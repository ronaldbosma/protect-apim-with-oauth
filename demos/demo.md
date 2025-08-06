# Protect API Management with OAuth - Demo

In this demo scenario, we will demonstrate how to protect an API in Azure API Management using OAuth.

The template deploys a Protected API in Azure API Management, which is secured with OAuth. It also deploys an app registration in Entra ID that represents the API Management service, and two app registrations that represent the client applications. One that can access the API and one that does not have access to the API. See the following diagram for an overview:

![Overview](https://raw.githubusercontent.com/ronaldbosma/protect-apim-with-oauth/refs/heads/main/images/diagrams-overview.png)

## 1. What resources are getting deployed

The following resources will be deployed in a resource group in your Azure subscription:

![Deployed Resources](https://raw.githubusercontent.com/ronaldbosma/protect-apim-with-oauth/refs/heads/main/images/deployed-resources.png)

The following app registrations will be created in your Entra ID tenant:

![Deployed App Registrations](https://raw.githubusercontent.com/ronaldbosma/protect-apim-with-oauth/refs/heads/main/images/deployed-app-registrations.png)

The deployed resources follow the naming convention: `<resource-type>-<environment-name>-<region>-<instance>`.


## 2. What can I demo from this scenario after deployment

### Gather data and create client secrets

We'll first need to gather some data and create client secrets for both clients:

1. Navigate to your [app registrations](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps) in Entra ID.

2. Open the app registration that represents the API Management service, which is named `appreg-<environment-name>-<region>-apim-<instance>`. For example, `appreg-oauth-sdc-apim-wiyuo`.

3. Copy the `Directory (tenant) ID` and `Application ID URI` from the overview page.

4. Navigate back to your app registrations.

5. Open the app registration that represents a valid client, which is named `appreg-<environment-name>-<region>-validclient-<instance>`. For example, `appreg-oauth-sdc-validclient-wiyuo`.

6. Copy the `Application (client) ID` from the overview page.

7. In the left-hand menu, select `Certificates & secrets`.

8. Under `Client secrets`, click on `New client secret`.

9. Add a description and set an expiration period for the secret.

10. Click `Add` and make sure to copy the secret value. You will need it later.

11. Repeat **steps 5-10** for the `invalidclient` app registration.

12. Navigate to the newly created resource group where the API Management service is deployed and copy the `API Management service name`.


### Configure the REST Client extension in Visual Studio Code

We'll use [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension in Visual Studio Code to call the API. 
Follow these steps to configure an environment for the REST Client:

1. Add an environment to your Visual Studio Code user settings with the OAuth settings ad API Management hostname. Use the following example and replace the values with your own:
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

   1. Replace `<directory-tenant-id>` with the ``Directory (tenant) ID` you copied earlier.
   1. Replace `<valid-application-client-id>` with `Application (client) ID` of the valid client app registration you copied earlier.
   1. Replace `<valid-client-secret>` with the client secret you created for the `validclient` app registration.
   1. Replace `<application-id-uri>` with the `Application ID URI` you copied earlier. Note that this value should end with `/.default`.
   1. Replace `<your-api-management-name>` with the name of your API Management service

1. Also add an environment for the invalid client following the same steps as above, but use the values from the `invalidclient` app registration.

1. Your final user settings should look like this:

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


### Call the API using the valid client

1. Open the [tests.http](https://github.com/ronaldbosma/protect-apim-with-oauth/blob/main/tests/tests.http) file in Visual Studio Code.

1. At the right bottom, select the `validclient` environment.

1. Click on the `Send Request` button of the first request `Get a token from Entra ID` to get an access token. 
   A 200 Ok response is returned with the access token in the body.

1. Copy the access token and inspect it on https://jwt.ms/.  

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

    Some important claims to note in the token:
    1. The audience (`aud`) should match the `Application (client) ID` of the app registration that represents the API Management service.
    1. The issuer (`iss`) and tenant ID (`tid`) should match the `Directory (tenant) ID`
    1. The authorized party (`azp`) should match the `Application (client) ID` of the client app registration that you used to get the token.
    1. The object ID (`oid`) and subject (`sub`) should match the object ID of service principal (enterprise application) of the client app registration.
    1. The roles (`roles`) should match the roles assigned to the client. For the valid client, this should be `Sample.Read` and `Sample.Write`.

1. Click on the `Send Request` button of the other three requests. 
   The `GET` and `POST` request return a 200 OK response with the token details. 
   The `DELETE` request returns a 401 Unauthorized response, because the valid client does not have the `Sample.Delete` role assigned.  

   > Note that the requests return a lot of details for demo purposes that you normally would not want to expose in a production environment.


### Call the API using the invalid client

1. At the right bottom, select the `invalidclient` environment.

1. Click on the `Send Request` button of the first request `Get a token from Entra ID` to get an access token. 
   A 400 Bad Request response is returned with an error message that the client is not authorized to access the API Management service. 
   This is because `appRoleAssignmentRequired` is set to `true` on the service principal of the app registration that represents the API Management service, which means that only clients that have a role assigned can retrieve an access token. See [apim-app-registration.bicep](https://github.com/ronaldbosma/protect-apim-with-oauth/blob/main/infra/modules/entra-id/apim-app-registration.bicep).