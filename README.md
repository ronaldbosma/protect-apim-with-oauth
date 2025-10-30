# Protect API Management with OAuth

An Azure Developer CLI (`azd`) template using Bicep to demonstrate how to secure an API in Azure API Management with OAuth. 
It includes examples for deploying app registrations in Entra ID using Bicep.

## Overview

This template deploys the following resources:

![Overview](images/diagrams-overview.png)

The template creates an API Management service with an OAuth-protected API. 
It also deploys three Entra ID app registrations using the [Microsoft Graph Bicep Extension](https://learn.microsoft.com/en-us/community/content/microsoft-graph-bicep-extension): 
one app registration that represents the APIs in API Management, one client with 'read' and 'write' permissions and one client with no API access (for testing authorization failures).
Additionally, Application Insights and Log Analytics Workspace are deployed for monitoring and logging purposes.

Want to learn more about how this template works? Check out the accompanying blog post [Protect APIs in Azure API Management with OAuth](https://ronaldbosma.github.io/blog/2025/09/16/protect-apis-in-azure-api-management-with-oauth/).

If you want to learn more about calling OAuth-Protected APIs from Azure API Management, check out the following resources:
- [Call API Management with Managed Identity](https://github.com/ronaldbosma/call-apim-with-managed-identity)
- [Call API Management backend with OAuth](https://github.com/ronaldbosma/call-apim-backend-with-oauth)

> [!IMPORTANT]  
> This template is not production-ready; it uses minimal cost SKUs and omits network isolation, advanced security, governance and resiliency. Harden security, implement enterprise controls and/or replace modules with [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/) before any production use.

## Getting Started

### Prerequisites  

Before you can deploy this template, make sure you have the following tools installed and the necessary permissions.

**Required Tools:**
- [Azure Developer CLI (azd)](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd)  
  Installing `azd` also installs the following tools:  
  - [GitHub CLI](https://cli.github.com)  
  - [Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)  
- This template includes several hooks that run at different stages of the deployment process and require the following tools. For more details, see [Hooks](#hooks).
  - [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell)
  - [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

**Required Permissions:**
- You need **Owner** or **Contributor** permissions on an Azure Subscription to deploy this template.  
- You need **Application Administrator** or **Cloud Application Administrator** permissions to register the Entra ID app registrations. 
  _(You already have enough permissions if 'Users can register applications' is enabled in your Entra tenant.)_

### Deployment

Once the prerequisites are installed on your machine, you can deploy this template using the following steps:

1. Run the `azd init` command in an empty directory with the `--template` parameter to clone this template into the current directory.  

    ```cmd
    azd init --template ronaldbosma/protect-apim-with-oauth
    ```

    When prompted, specify the name of the environment, for example, `oauth`. The maximum length is 32 characters.

1. Run the `azd auth login` command to authenticate to your Azure subscription using the **Azure Developer CLI** _(if you haven't already)_.

    ```cmd
    azd auth login
    ```

1. Run the `az login` command to authenticate to your Azure subscription using the **Azure CLI** _(if you haven't already)_. This is required for the [hooks](#hooks) to function properly. Make sure to log into the same tenant as the Azure Developer CLI.

    ```cmd
    az login
    ```

1. Run the `azd up` command to provision the resources in your Azure subscription and Entra ID tenant. This deployment typically takes around 4 minutes to complete.

    ```cmd
    azd up
    ```

    See [Troubleshooting](#troubleshooting) if you encounter any issues during deployment.

1. Once the deployment is complete, you can locally modify the application or infrastructure and run `azd up` again to update the resources in Azure.

### Demo and Test

The [Demo Guide](demos/demo.md) provides a step-by-step walkthrough on how to test and demonstrate the deployed resources.

### Clean up

Once you're done and want to clean up, run the `azd down` command. By including the `--purge` parameter, you ensure that the API Management service doesn't remain in a soft-deleted state, which could block future deployments of the same environment.

```cmd
azd down --purge
```


## Contents

The repository consists of the following files and directories:

```
├── demos                      [ Demo guide(s) ]
├── hooks                      [ AZD Hooks to execute at different stages of the deployment process ]
├── images                     [ Images used in the README and demo guide ]
├── infra                      [ Infrastructure As Code files ]
│   |── functions              [ Bicep user-defined functions ]
│   ├── modules                
│   │   ├── application        [ The protected API ]
│   │   ├── entra-id           [ Modules for all Entra ID resources ]
│   │   └── services           [ Modules for all Azure services ]
│   ├── types                  [ Bicep user-defined types ]
│   ├── main.bicep             [ Main infrastructure file ]
│   └── main.parameters.json   [ Parameters file ]
├── tests                      
│   └── tests.http             [ HTTP requests to test the deployed resources ]
├── azure.yaml                 [ Describes the apps and types of Azure resources ]
└── bicepconfig.json           [ Bicep configuration file ]
```


## Hooks

This template has several hooks that are executed at different stages of the deployment process. The following hooks are included:

### Pre-down hooks

These PowerShell scripts are executed before the resources are removed.

- [predown-remove-app-registrations.ps1](hooks/predown-remove-app-registrations.ps1): 
  Removes the app registrations created during the deployment process, because `azd` doesn't support deleting Entra ID resources yet. 
  See the related GitHub issue: https://github.com/Azure/azure-dev/issues/4724.
  We're using a predown hook because the environment variables are (sometimes) empty in a postdown hook.
  
- [predown-remove-law.ps1](hooks/predown-remove-law.ps1): 
  Permanently deletes the Log Analytics workspace to prevent issues with future deployments. 
  Sometimes the requests and traces don't show up in Application Insights & Log Analytics when removing and deploying the template multiple times.
  A predown hook is used and not a postdown hook because permanent deletion of the workspace doesn't work
  if it's already in the soft-deleted state after azd has removed it.


## Troubleshooting

### API Management deployment failed because the service already exists in soft-deleted state

If you've previously deployed this template and deleted the resources, you may encounter the following error when redeploying the template. This error occurs because the API Management service is in a soft-deleted state and needs to be purged before you can create a new service with the same name.

```json
{
    "code": "DeploymentFailed",
    "target": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-oauth-sdc-wiyuo/providers/Microsoft.Resources/deployments/apiManagement",
    "message": "At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/arm-deployment-operations for usage details.",
    "details": [
        {
            "code": "ServiceAlreadyExistsInSoftDeletedState",
            "message": "Api service apim-oauth-sdc-wiyuo was soft-deleted. In order to create the new service with the same name, you have to either undelete the service or purge it. See https://aka.ms/apimsoftdelete."
        }
    ]
}
```

Use the [az apim deletedservice list](https://learn.microsoft.com/en-us/cli/azure/apim/deletedservice?view=azure-cli-latest#az-apim-deletedservice-list) Azure CLI command to list all deleted API Management services in your subscription. Locate the service that is in a soft-deleted state and purge it using the [purge](https://learn.microsoft.com/en-us/cli/azure/apim/deletedservice?view=azure-cli-latest#az-apim-deletedservice-purge) command. See the following example:

```cmd
az apim deletedservice purge --location "swedencentral" --service-name "apim-oauth-sdc-wiyuo"
```
