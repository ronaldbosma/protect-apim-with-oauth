//=============================================================================
// Protect API Management with OAuth
// Source: https://github.com/ronaldbosma/protect-apim-with-oauth
//=============================================================================

targetScope = 'subscription'

//=============================================================================
// Imports
//=============================================================================

import { getResourceName, getInstanceId } from './functions/naming-conventions.bicep'
import * as settings from './types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@minLength(1)
@description('Location to use for all resources')
param location string

@minLength(1)
@maxLength(32)
@description('The name of the environment to deploy to')
param environmentName string

@maxLength(5) // The maximum length of the storage account name and key vault name is 24 characters. To prevent errors the instance name should be short.
@description('The instance that will be added to the deployed resources names to make them unique. Will be generated if not provided.')
param instance string = ''

//=============================================================================
// Variables
//=============================================================================

// Determine the instance id based on the provided instance or by generating a new one
var instanceId = getInstanceId(environmentName, location, instance)

var resourceGroupName = getResourceName('resourceGroup', environmentName, location, instanceId)

var apiManagementSettings = {
  serviceName: getResourceName('apiManagement', environmentName, location, instanceId)
  publisherName: 'admin@example.org'
  publisherEmail: 'admin@example.org'
}

var appInsightsSettings = {
  appInsightsName: getResourceName('applicationInsights', environmentName, location, instanceId)
  logAnalyticsWorkspaceName: getResourceName('logAnalyticsWorkspace', environmentName, location, instanceId)
  retentionInDays: 30
}

var clientName = getResourceName('client', environmentName, location, instanceId)

var functionAppSettings = {
  functionAppName: getResourceName('functionApp', environmentName, location, instanceId)
  appServicePlanName: getResourceName('appServicePlan', environmentName, location, 'functionapp-${instanceId}')
  netFrameworkVersion: 'v9.0'
}

var logicAppSettings = {
  logicAppName: getResourceName('logicApp', environmentName, location, instanceId)
  appServicePlanName: getResourceName('appServicePlan', environmentName, location, 'logicapp-${instanceId}')
  netFrameworkVersion: 'v9.0'
}

var keyVaultName = getResourceName('keyVault', environmentName, location, instanceId)

var storageAccountName = getResourceName('storageAccount', environmentName, location, instanceId)

var tags = {
  'azd-env-name': environmentName
  'azd-template': 'ronaldbosma/protect-apim-with-oauth'
}

//=============================================================================
// Resources
//=============================================================================

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module entraId 'modules/entra-id.bicep' = {
  name: 'entraId'
  params: {
    tenantId: subscription().tenantId
    tags: tags
    apiManagementServiceName: apiManagementSettings.serviceName
    clientName: clientName
  }
}

module services 'modules/services.bicep' = {
  name: 'services'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    apiManagementSettings: apiManagementSettings
    appInsightsSettings: appInsightsSettings
    functionAppSettings: functionAppSettings
    logicAppSettings: logicAppSettings
    keyVaultName: keyVaultName
    storageAccountName: storageAccountName
  }
}

//=============================================================================
// Application Resources
//=============================================================================

module protectedApi 'modules/application/protected-api.bicep' = {
  name: 'protectedApi'
  scope: resourceGroup
  params: {
    apiManagementServiceName: apiManagementSettings.serviceName
    tenantId: subscription().tenantId
    jwtAudience: entraId.outputs.apiManagementAppId
  }
}

module unprotectedApi 'modules/application/unprotected-api.bicep' = {
  name: 'unprotectedApi'
  scope: resourceGroup
  params: {
    apiManagementServiceName: apiManagementSettings.serviceName
  }
}

//=============================================================================
// Outputs
//=============================================================================

// Return names of the Entra ID resources
output ENTRA_ID_APIM_APPLICATION_NAME string = apiManagementSettings.serviceName
output ENTRA_ID_APIM_CLIENT_NAME string = clientName

// Return the names of the resources
output AZURE_API_MANAGEMENT_NAME string = apiManagementSettings.serviceName
output AZURE_APPLICATION_INSIGHTS_NAME string = appInsightsSettings.appInsightsName
output AZURE_FUNCTION_APP_NAME string = functionAppSettings.functionAppName
output AZURE_KEY_VAULT_NAME string = keyVaultName
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = appInsightsSettings.logAnalyticsWorkspaceName
output AZURE_LOGIC_APP_NAME string = logicAppSettings.logicAppName
output AZURE_RESOURCE_GROUP string = resourceGroupName
output AZURE_STORAGE_ACCOUNT_NAME string = storageAccountName
