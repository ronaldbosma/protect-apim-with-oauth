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
  appRegistrationName: getResourceName('appRegistration', environmentName, location, 'apim-${instanceId}')
  appRegistrationIdentifierUri: 'api://${getResourceName('apiManagement', environmentName, location, instanceId)}'
}

var appInsightsSettings = {
  appInsightsName: getResourceName('applicationInsights', environmentName, location, instanceId)
  logAnalyticsWorkspaceName: getResourceName('logAnalyticsWorkspace', environmentName, location, instanceId)
  retentionInDays: 30
}

var clientAppRegistrationName = getResourceName('appRegistration', environmentName, location, 'client-${instanceId}')

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

var storageAccountName = getResourceName('storageAccount', environmentName, location, instanceId)

var tags = {
  'azd-env-name': environmentName
  'azd-template': 'ronaldbosma/protect-apim-with-oauth'
}

//=============================================================================
// Resources
//=============================================================================

module apimAppRegistration 'modules/entra-id/apim-app-registration.bicep' = {
  name: 'apimAppRegistration'
  params: {
    tenantId: subscription().tenantId
    tags: tags
    apimAppRegistrationName: apiManagementSettings.appRegistrationName
    identifierUri: apiManagementSettings.appRegistrationIdentifierUri
  }
}

module clientAppRegistration 'modules/entra-id/client-app-registration.bicep' = {
  name: 'clientAppRegistration'
  params: {
    tags: tags
    clientAppRegistrationName: clientAppRegistrationName
  }
  dependsOn: [
    apimAppRegistration
  ]
}

module assignAppRolesToClient 'modules/entra-id/assign-app-roles.bicep' = {
  name: 'assignAppRolesToClient'
  params: {
    apimAppRegistrationName: apiManagementSettings.appRegistrationName
    clientAppRegistrationName: clientAppRegistrationName
  }
  dependsOn: [
    clientAppRegistration
    apimAppRegistration
    // Assignment of the app roles fails if we do this immediately after creating the app registrations.
    // By adding a dependency on the API Management module, we ensure that enough time has passed for the app role assignments to succeed.
    apiManagement 
  ]
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module storageAccount 'modules/services/storage-account.bicep' = {
  name: 'storageAccount'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    storageAccountName: storageAccountName
  }
}

module appInsights 'modules/services/app-insights.bicep' = {
  name: 'appInsights'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    appInsightsSettings: appInsightsSettings
  }
}

module apiManagement 'modules/services/api-management.bicep' = {
  name: 'apiManagement'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    apiManagementSettings: apiManagementSettings
    appInsightsName: appInsightsSettings.appInsightsName
  }
  dependsOn: [
    appInsights
  ]
}

module functionApp 'modules/services/function-app.bicep' = {
  name: 'functionApp'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    functionAppSettings: functionAppSettings
    apiManagementSettings: apiManagementSettings
    appInsightsName: appInsightsSettings.appInsightsName
    storageAccountName: storageAccountName
  }
  dependsOn: [
    appInsights
    storageAccount
  ]
}

module logicApp 'modules/services/logic-app.bicep' = {
  name: 'logicApp'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    logicAppSettings: logicAppSettings
    apiManagementSettings: apiManagementSettings
    appInsightsName: appInsightsSettings.appInsightsName
    storageAccountName: storageAccountName
  }
  dependsOn: [
    appInsights
    storageAccount
  ]
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
    oauthAudience: apimAppRegistration.outputs.appId
  }
  dependsOn: [
    apiManagement
  ]
}

module unprotectedApi 'modules/application/unprotected-api.bicep' = {
  name: 'unprotectedApi'
  scope: resourceGroup
  params: {
    apiManagementServiceName: apiManagementSettings.serviceName
    appRegistrationIdentifierUri: apiManagementSettings.appRegistrationIdentifierUri
  }
  dependsOn: [
    apiManagement
  ]
}

//=============================================================================
// Outputs
//=============================================================================

// Return names of the Entra ID resources
output ENTRA_ID_APIM_APP_REGISTRATION_NAME string = apiManagementSettings.appRegistrationName
output ENTRA_ID_CLIENT_APP_REGISTRATION_NAME string = clientAppRegistrationName

// Return the names of the resources
output AZURE_API_MANAGEMENT_NAME string = apiManagementSettings.serviceName
output AZURE_APPLICATION_INSIGHTS_NAME string = appInsightsSettings.appInsightsName
output AZURE_FUNCTION_APP_NAME string = functionAppSettings.functionAppName
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = appInsightsSettings.logAnalyticsWorkspaceName
output AZURE_LOGIC_APP_NAME string = logicAppSettings.logicAppName
output AZURE_RESOURCE_GROUP string = resourceGroupName
output AZURE_STORAGE_ACCOUNT_NAME string = storageAccountName
