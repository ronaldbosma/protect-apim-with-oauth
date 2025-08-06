# Protect API Management with OAuth - Demo

In this demo scenario, we will demonstrate how to protect an API in Azure API Management using OAuth. The template includes the necessary resources and configurations to deploy app registrations in Entra ID using Bicep.

![Overview](https://github.com/ronaldbosma/protect-apim-with-oauth/refs/heads/main/images/diagrams-overview.png)

## 1. What resources are getting deployed

The following resources will be deployed in a resource group in your Azure subscription:

![Deployed Resources](https://github.com/ronaldbosma/protect-apim-with-oauth/refs/heads/main/images/deployed-resources.png)

The following app registrations will be created in your Entra ID tenant:

![Deployed App Registrations](https://github.com/ronaldbosma/protect-apim-with-oauth/refs/heads/main/images/deployed-app-registrations.png)

The deployed resources follow the naming convention: `<resource-type>-<environment-name>-<region>-<instance>`.


## 2. What can I demo from this scenario after deployment

1. Navigate to your [app registrations](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps) in Entra ID.
