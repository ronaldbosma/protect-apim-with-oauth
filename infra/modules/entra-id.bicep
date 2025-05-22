//=============================================================================
// Entra ID
//=============================================================================

targetScope = 'subscription'

//=============================================================================
// Extensions
//=============================================================================

extension microsoftGraphV1

//=============================================================================
// Parameters
//=============================================================================

@description('The ID of the tenant')
param tenantId string

@description('The tags to associate with the resource')
param tags object

@description('The name of the API Management Service')
param apiManagementServiceName string

@description('The name of the client')
param clientName string

//=============================================================================
// Resources
//=============================================================================

module apiManagementApp 'entra-id/api-management-app.bicep' = {
  name: 'apiManagementApp'
  params: {
    tenantId: tenantId
    tags: tags
    apiManagementServiceName: apiManagementServiceName
  }
}

module clientApp 'entra-id/client-app.bicep' = {
  name: 'clientApp'
  params: {
    tags: tags
    apiManagementAppName: apiManagementServiceName
    clientName: clientName
  }
  dependsOn: [
    apiManagementApp
  ]
}

//=============================================================================
// Outputs
//=============================================================================

output apiManagementAppId string = apiManagementApp.outputs.appId
