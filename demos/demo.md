# Protect API Management with OAuth - Demo

This demo shows how to protect an API in Azure API Management using OAuth.

The template deploys a protected API in Azure API Management secured with OAuth. It also deploys an app registration in Entra ID that represents the API Management service and two app registrations for client applications. One client can access the API and one cannot. See the following diagram for an overview:

![Overview](https://raw.githubusercontent.com/ronaldbosma/protect-apim-with-oauth/refs/heads/main/images/diagrams-overview.png)

## 1. What resources get deployed

The following resources are deployed in a resource group in your Azure subscription:

![Deployed Resources](https://raw.githubusercontent.com/ronaldbosma/protect-apim-with-oauth/refs/heads/main/images/deployed-resources.png)

The following app registrations are created in your Entra ID tenant:

![Deployed App Registrations](https://raw.githubusercontent.com/ronaldbosma/protect-apim-with-oauth/refs/heads/main/images/deployed-app-registrations.png)

The deployed resources follow the naming convention: `<resource-type>-<environment-name>-<region>-<instance>`.

## 2. What you can demo after deployment

### Test the protected API

After deployment completes, you can test the protected API using the steps in this section.
The API is protected with OAuth, so you'll need to obtain an access token from Entra ID using the client credentials flow.
You'll use the access token to call the API.
See the following sequence diagram for an overview:

![Sequence Diagram](https://raw.githubusercontent.com/ronaldbosma/protect-apim-with-oauth/refs/heads/main/images/diagrams-sequence-diagram.png)

#### Gather data and create client secrets

First, you'll need to gather some data and create client secrets for both clients.
Keep track of these values because you'll need them later.

1. Navigate to your [app registrations](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps) in Entra ID.

2. Open the app registration that represents the API Management service, which is named `appreg-<environment-name>-<region>-apim-<instance>`. For example, `appreg-oauth-sdc-apim-wiyuo`.

3. Copy the `Directory (tenant) ID` and `Application ID URI` from the overview page.

4. Navigate back to your app registrations.

5. Open the app registration that represents a valid client, which is named `appreg-<environment-name>-<region>-validclient-<instance>`. For example, `appreg-oauth-sdc-validclient-wiyuo`.

6. Copy the `Application (client) ID` from the overview page.

7. In the left-hand menu, select `Certificates & secrets`.

8. Under `Client secrets`, click on `New client secret`.

   > **Note:** There should already be a client secret present that was generated during deployment and stored in Key Vault. This secret is used by the integration tests. You can retrieve its value from Key Vault if needed, or create a new one.

9. Add a description and set an expiration period for the secret.

10. Click `Add` and copy the secret value (you won't be able to see it again).

11. Repeat **steps 5-10** for the `invalidclient` app registration.

12. Navigate to the newly created resource group where the API Management service is deployed and copy the `API Management service name`.

#### Configure the REST Client extension in Visual Studio Code

You'll use the [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension in Visual Studio Code to call the API.
Follow these steps to configure an environment for the REST Client:

1. Add an environment to your Visual Studio Code user settings with the OAuth settings and API Management hostname. Use the following example and replace the values with your own:

   ```
   {
       ... MORE SETTINGS HERE ...
       "rest-client.environmentVariables": {
           "validclient": {
               "tenantId": "<directory-tenant-id>",
               "clientId": "<valid-application-client-id>",
               "clientSecret": "<valid-client-secret>",
               "clientScope": "<application-id-uri>/.default",
               "apimHostname": "<your-api-management-name>.azure-api.net"
           }
       },
       ... MORE SETTINGS HERE ...
   }
   ```

   1. Replace `<directory-tenant-id>` with the `Directory (tenant) ID` you copied earlier.
   1. Replace `<valid-application-client-id>` with the `Application (client) ID` of the valid client app registration you copied earlier.
   1. Replace `<valid-client-secret>` with the client secret you created for the `validclient` app registration.
   1. Replace `<application-id-uri>` with the `Application ID URI` you copied earlier. This value should end with `/.default`.
   1. Replace `<your-api-management-name>` with the name of your API Management service.

1. Add a second environment for the invalid client following the same steps as above, but use the values from the `invalidclient` app registration.

1. Your final user settings should look similar to this:

   ```json
   {
       ... MORE SETTINGS HERE ...
       "rest-client.environmentVariables": {
           "validclient": {
               "tenantId": "00000000-0000-0000-0000-000000000000",
               "clientId": "f2b24498-3c66-46cd-9a61-92acb473b959",
               "clientSecret": "ESF...",
               "clientScope": "api://apim-oauth-sdc-wiyuo/.default",
               "apimHostname": "apim-oauth-sdc-wiyuo.azure-api.net"
           },
           "invalidclient": {
               "tenantId": "00000000-0000-0000-0000-000000000000",
               "clientId": "c28d676a-f26e-4a85-909d-10385b857415",
               "clientSecret": "pHG...",
               "clientScope": "api://apim-oauth-sdc-wiyuo/.default",
               "apimHostname": "apim-oauth-sdc-wiyuo.azure-api.net"
           }
       },
       ... MORE SETTINGS HERE ...
   }
   ```

#### Call the API using the valid client

Once you have the environments set up, you can start calling the API using the valid client:

1. Open the [tests.http](https://github.com/ronaldbosma/protect-apim-with-oauth/blob/main/tests/tests.http) file in Visual Studio Code.

1. To select the `validclient` Rest Client environment, use either of the following options:
   - Option 1: Click on `No Environment` in the bottom right corner of the status bar.
   - Option 2: Press `Ctrl` + `Alt` + `E`.
   - Option 3: Press `F1`, type **Rest Client: Switch Environment**

1. Review the first request `Get a token from Entra ID`.
   This request uses the OAuth 2.0 client credentials flow to authenticate with Entra ID. The client ID and client secret are included in the request body for authentication.
   The scope parameter, constructed from the `Application ID URI` of the API Management app registration (ending with `/.default`), specifies to Entra ID which resource the token should be retrieved for.

   See the following diagram for a mapping between the HTTP request and the properties of the app registrations:

   ![HTTP Request Mapping](https://raw.githubusercontent.com/ronaldbosma/protect-apim-with-oauth/refs/heads/main/images/diagrams-http-request-mapping.png)

1. Review the other three requests in the `tests.http` file.
   The retrieved access token is passed as a bearer token in the `Authorization` header.

1. Click on the `Send Request` button of the request `Get a token from Entra ID` to get an access token.
   A 200 OK response is returned with the access token in the body.

1. Copy the access token and inspect it on https://jwt.ms/.
   It should look similar to the following (the signature part is omitted for brevity):

   ```json
   {
       "typ": "JWT",
       "alg": "RS256",
       "kid": "JYhAcTPMZ_LX6DBlOWQ7Hn0NeXE"
   }.{
       "aud": "d03a9bf4-b880-4793-926f-95bb5ce74a77",
       "iss": "https://login.microsoftonline.com/00000000-0000-0000-0000-000000000000/v2.0",
       "iat": 1754479503,
       "nbf": 1754479503,
       "exp": 1754483403,
       "aio": "k2RgYNDW+nl2ucdDVvv8Ik3Pc3UsSmuMD1S51RUozP9Rb5qd+xQA",
       "azp": "f2b24498-3c66-46cd-9a61-92acb473b959",
       "azpacr": "1",
       "oid": "99f268b3-61d1-4536-bfd5-85f426e2146f",
       "rh": "1.AREApJh_vYXSgkKIneLd7SzgtfSbOtCAuJNHkm-Vu1znSne2AQARAA.",
       "roles": [
           "Sample.Read",
           "Sample.Write"
       ],
       "sub": "99f268b3-61d1-4536-bfd5-85f426e2146f",
       "tid": "00000000-0000-0000-0000-000000000000",
       "uti": "u1TnRc8ca062Otegxw1eAA",
       "ver": "2.0",
       "xms_ftd": "6GV3Fo3zqLYcRXidCxeF67AEtuoaRaCrIosJCrS7IyEBc3dlZGVuYy1kc21z"
   }.[Signature]
   ```

   Key claims to note in the token:
   1. The audience (`aud`) should match the `Application (client) ID` of the app registration that represents the API Management service.
   1. The issuer (`iss`) and tenant ID (`tid`) should match the `Directory (tenant) ID`.
   1. The authorized party (`azp`) should match the `Application (client) ID` of the client app registration you used to get the token.
   1. The object ID (`oid`) and subject (`sub`) should match the object ID of the service principal (enterprise application) of the client app registration.
   1. The `roles` should match the roles assigned to the client. For the valid client, this should be `Sample.Read` and `Sample.Write`.

   See the following diagram for a mapping between the JWT token and the properties of the app registrations:

   ![JWT Token Mapping](https://raw.githubusercontent.com/ronaldbosma/protect-apim-with-oauth/refs/heads/main/images/diagrams-jwt-token-mapping.png)

1. Click on the `Send Request` button of the other three requests.
   1. The `GET` and `POST` requests return a 200 OK response with the token details.
   1. The `DELETE` request returns a 401 Unauthorized response because the valid client doesn't have the `Sample.Delete` role assigned.

> Note that the requests return a lot of details for demo purposes that you normally would not want to expose in a production environment.

#### Call the API using the invalid client

Follow these steps to call the API using the invalid client:

1. At the bottom right, select the `invalidclient` environment.

1. Click on the `Send Request` button of the first request `Get a token from Entra ID` to get an access token.
   A 400 Bad Request response is returned with an error message that the client isn't authorized to access the API Management service.
   This is because `appRoleAssignmentRequired` is set to `true` on the service principal of the app registration that represents the API Management service, which means only clients that have a role assigned can retrieve an access token. See [apim-app-registration.bicep](https://github.com/ronaldbosma/protect-apim-with-oauth/blob/main/infra/modules/entra-id/apim-app-registration.bicep).

### Review the configuration files

#### Review the Entra ID Bicep modules

The app registrations are deployed using the [Microsoft Graph Bicep Extension](https://learn.microsoft.com/en-us/community/content/microsoft-graph-bicep-extension).

The app registration and service principal that represents the API Management service is deployed in [apim-app-registration.bicep](https://github.com/ronaldbosma/protect-apim-with-oauth/blob/main/infra/modules/entra-id/apim-app-registration.bicep).
It specifies the following:

- The `identifierUris` (`Application ID URI`) is set to `api://<apim-service-name>`. It's used as the scope when requesting an access token.
- The `requestedAccessTokenVersion` property is set to `2`, which means OAuth 2.0 tokens are issued.
- The `appRoles` property specifies the available roles that can be assigned to clients.
- The `appRoleAssignmentRequired` property on the service principal is set to `true`, which means only clients that have a role assigned can retrieve an access token.

The app registrations and service principals that represent the client applications are deployed with [client-app-registration.bicep](https://github.com/ronaldbosma/protect-apim-with-oauth/blob/main/infra/modules/entra-id/client-app-registration.bicep).

Assignment of the roles to the valid client is done using [assign-app-roles.bicep](https://github.com/ronaldbosma/protect-apim-with-oauth/blob/main/infra/modules/entra-id/assign-app-roles.bicep).

#### Review the protected API

The protected API deployed in Azure API Management can be accessed via the Azure portal.

![Protected API](https://raw.githubusercontent.com/ronaldbosma/protect-apim-with-oauth/refs/heads/main/images/protected-api.png)

The API has three operations:

- The `GET` that requires the `Sample.Read` role.
- The `POST` that requires the `Sample.Write` role.
- The `DELETE` that requires the `Sample.Delete` role.

A policy is deployed at the API scope using [protected-api.xml](https://github.com/ronaldbosma/protect-apim-with-oauth/blob/main/infra/modules/application/protected-api.xml). The policy:

- Checks which request was performed based on the HTTP method and determines which role is required.
- Validates the access token in the `Authorization` header using the [validate-azure-ad-token](https://learn.microsoft.com/en-us/azure/api-management/validate-azure-ad-token-policy) policy.
  - The `tenant-id` named value contains the `Directory (tenant) ID` of your Entra ID tenant.
  - The `oauth-audience` named value contains the `Application (client) ID` of the app registration that represents the API Management service.
- Returns a 200 OK response with the token details if the access token is valid and the client has the required role.
- When an error occurs, it returns the details of the error in the response body.

> Note that the API returns a lot of details for demo purposes that you normally wouldn't want to expose in a production environment.

##### Alternative to validate-azure-ad-token policy

As an alternative to the `validate-azure-ad-token` policy, you can use the [validate-jwt](https://learn.microsoft.com/en-us/azure/api-management/validate-jwt-policy) policy to validate the access token.
Here's an example of how to configure the `validate-jwt` policy using Entra ID, but it also works with different Identity Providers that support OpenID Connect:

```
<validate-jwt header-name="Authorization">
    <openid-config url="https://login.microsoftonline.com/{{tenant-id}}/v2.0/.well-known/openid-configuration" />
    <audiences>
        <audience>{{oauth-audience}}</audience>
    </audiences>
    <required-claims>
        <claim name="roles" match="any">
            <value>@((string)context.Variables["role"])</value>
        </claim>
    </required-claims>
</validate-jwt>
```
