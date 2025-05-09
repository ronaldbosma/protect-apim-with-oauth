//=============================================================================
// Entra ID
//=============================================================================

//=============================================================================
// Extensions
//=============================================================================

extension microsoftGraphV1

//=============================================================================
// Parameters
//=============================================================================

@description('The ID of the tenant')
param tenantId string

@description('The name of the API Management Service')
param apiManagementServiceName string

//=============================================================================
// Resources
//=============================================================================

module apiManagementApp 'entra-id/api-management-app.bicep' = {
  name: 'apiManagementApp'
  params: {
    tenantId: tenantId
    apiManagementServiceName: apiManagementServiceName
  }
}
