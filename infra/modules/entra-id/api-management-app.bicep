//=============================================================================
// API Management App Registration & Service Principal
//=============================================================================

//=============================================================================
// Extensions
//=============================================================================

extension microsoftGraphV1

//=============================================================================
// Imports
//=============================================================================

import * as helpers from '../../functions/helpers.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The ID of the tenant')
param tenantId string

@description('The tags to associate with the resource')
param tags object

@description('The name of the API Management Service')
param apiManagementServiceName string

//=============================================================================
// Resources
//=============================================================================

resource apimAppRegistration 'Microsoft.Graph/applications@v1.0' = {
  tags: helpers.flattenTags(tags)
  
  uniqueName: apiManagementServiceName
  displayName: apiManagementServiceName

  identifierUris: [
    'api://${apiManagementServiceName}'
  ]

  appRoles: [
    {
      id: guid(tenantId, 'Sample.Read')
      description: 'Sample read application role'
      displayName: 'Sample.Read'
      value: 'Sample.Read'
      allowedMemberTypes: [ 'Application' ]
      isEnabled: true
    }
    {
      id: guid(tenantId, 'Sample.Write')
      description: 'Sample write application role'
      displayName: 'Sample.Write'
      value: 'Sample.Write'
      allowedMemberTypes: [ 'Application' ]
      isEnabled: true
    }
  ]

  owners: {
    relationships: [
      deployer().objectId
    ]
  }
}

resource apimServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: apimAppRegistration.appId
  appRoleAssignmentRequired: true
}
