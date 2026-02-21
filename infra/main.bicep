//=============================================================================
// Protect API Management with OAuth
// Source: https://github.com/ronaldbosma/protect-apim-with-oauth
//=============================================================================

targetScope = 'subscription'

//=============================================================================
// Imports
//=============================================================================

import { getResourceName, generateInstanceId } from './functions/naming-conventions.bicep'
import { apiManagementSettingsType, appInsightsSettingsType } from './types/settings.bicep'

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

@description('The service management reference. Required for tenants with Entra IDs enabled by Service Tree management and must be a valid Service Tree ID in this case.')
param serviceManagementReference string = ''

//=============================================================================
// Variables
//=============================================================================

// Generate an instance ID to ensure unique resource names
var instanceId string = generateInstanceId(environmentName, location)

var resourceGroupName string = getResourceName('resourceGroup', environmentName, location, instanceId)

var apiManagementSettings apiManagementSettingsType = {
  serviceName: getResourceName('apiManagement', environmentName, location, instanceId)
  sku: 'Consumption'
  appRegistrationName: getResourceName('appRegistration', environmentName, location, 'apim-${instanceId}')
  appRegistrationIdentifierUri: 'api://${getResourceName('apiManagement', environmentName, location, instanceId)}'
}

var appInsightsSettings appInsightsSettingsType = {
  appInsightsName: getResourceName('applicationInsights', environmentName, location, instanceId)
  logAnalyticsWorkspaceName: getResourceName('logAnalyticsWorkspace', environmentName, location, instanceId)
  retentionInDays: 30
}

var validClientAppRegistrationName string = getResourceName('appRegistration', environmentName, location, 'validclient-${instanceId}')
var invalidClientAppRegistrationName string = getResourceName('appRegistration', environmentName, location, 'invalidclient-${instanceId}')

var keyVaultName string = getResourceName('keyVault', environmentName, location, instanceId)

// Generate a unique ID for the azd environment so we can identity the Entra ID resources created for this environment
// The environment name is not unique enough as multiple environments can have the same name in different subscriptions, regions, etc.
var azdEnvironmentId string = getResourceName('azdEnvironment', environmentName, location, instanceId)

var tags { *: string } = {
  'azd-env-name': environmentName
  'azd-env-id': azdEnvironmentId
  'azd-template': 'ronaldbosma/protect-apim-with-oauth'

  // The SecurityControl tag is added to Trainer Demo Deploy projects so resources can run in MTT managed subscriptions without being blocked by default security policies.
  // DO NOT USE this tag in production or customer subscriptions.
  SecurityControl: 'Ignore'
}

//=============================================================================
// Resources
//=============================================================================

module apimAppRegistration 'modules/entra-id/apim-app-registration.bicep' = {
  params: {
    tenantId: subscription().tenantId
    tags: tags
    name: apiManagementSettings.appRegistrationName
    identifierUri: apiManagementSettings.appRegistrationIdentifierUri
    serviceManagementReference: serviceManagementReference
  }
}

// This client is 'valid' because it will have app roles assigned to it.
module validClientAppRegistration 'modules/entra-id/client-app-registration.bicep' = {
  params: {
    tags: tags
    name: validClientAppRegistrationName
    serviceManagementReference: serviceManagementReference
  }
  dependsOn: [
    apimAppRegistration
  ]
}

module assignAppRolesToValidClient 'modules/entra-id/assign-app-roles.bicep' = {
  params: {
    apimAppRegistrationName: apiManagementSettings.appRegistrationName
    clientAppRegistrationName: validClientAppRegistrationName
  }
  dependsOn: [
    apimAppRegistration
    validClientAppRegistration
    // Assignment of the app roles fails if we do this immediately after creating the app registrations.
    // By adding a dependency on the API Management module, we ensure that enough time has passed for the app role assignments to succeed.
    apiManagement 
  ]
}

// This client is 'invalid' because it will not have app roles assigned to it.
module invalidClientAppRegistration 'modules/entra-id/client-app-registration.bicep' = {
  params: {
    tags: tags
    name: invalidClientAppRegistrationName
    serviceManagementReference: serviceManagementReference
  }
  dependsOn: [
    apimAppRegistration
  ]
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module appInsights 'modules/services/app-insights.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    appInsightsSettings: appInsightsSettings
  }
}

module apiManagement 'modules/services/api-management.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    apiManagementSettings: apiManagementSettings
    appInsightsName: appInsightsSettings.appInsightsName
    keyVaultName: keyVaultName
  }
  dependsOn: [
    appInsights
  ]
}

module keyVault 'modules/services/key-vault.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    keyVaultName: keyVaultName
  }
}

module assignRolesToDeployer 'modules/shared/assign-roles-to-principal.bicep' = {
  scope: resourceGroup
  params: {
    principalId: deployer().objectId
    isAdmin: true
    appInsightsName: appInsightsSettings.appInsightsName
    keyVaultName: keyVaultName
  }
  dependsOn: [
    appInsights
    keyVault
  ]
}

//=============================================================================
// Application Resources
//=============================================================================

module protectedApi 'modules/application/protected-api.bicep' = {
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

//=============================================================================
// Outputs
//=============================================================================

// Return the Azure tenant id so it is available in the .env file and can be used in e.g. the integration tests
output AZURE_TENANT_ID string = subscription().tenantId

// Return the azd environment id
output AZURE_ENV_ID string = azdEnvironmentId

// Return names of the Entra ID resources
output ENTRA_ID_APIM_APP_REGISTRATION_NAME string = apiManagementSettings.appRegistrationName
output ENTRA_ID_APIM_APP_REGISTRATION_IDENTIFIER_URI string = apiManagementSettings.appRegistrationIdentifierUri
output ENTRA_ID_VALID_CLIENT_APP_REGISTRATION_NAME string = validClientAppRegistrationName
output ENTRA_ID_VALID_CLIENT_APP_REGISTRATION_CLIENT_ID string = validClientAppRegistration.outputs.appId
output ENTRA_ID_INVALID_CLIENT_APP_REGISTRATION_NAME string = invalidClientAppRegistrationName
output ENTRA_ID_INVALID_CLIENT_APP_REGISTRATION_CLIENT_ID string = invalidClientAppRegistration.outputs.appId

// Return the names of the resources
output AZURE_API_MANAGEMENT_NAME string = apiManagementSettings.serviceName
output AZURE_APPLICATION_INSIGHTS_NAME string = appInsightsSettings.appInsightsName
output AZURE_KEY_VAULT_NAME string = keyVaultName
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = appInsightsSettings.logAnalyticsWorkspaceName
output AZURE_RESOURCE_GROUP string = resourceGroupName

// Return resource endpoints
output AZURE_API_MANAGEMENT_GATEWAY_URL string = apiManagement.outputs.gatewayUrl
output AZURE_KEY_VAULT_URI string = keyVault.outputs.vaultUri

// Return the service management reference
output AZURE_SERVICE_MANAGEMENT_REFERENCE string? = serviceManagementReference
