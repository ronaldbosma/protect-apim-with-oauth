//=============================================================================
// API Management App Registration & Service Principal
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

resource apimAppRegistration 'Microsoft.Graph/applications@v1.0' = {
  tags: [ 'tag-1', 'tag-2' ]
  
  uniqueName: apiManagementServiceName
  displayName: apiManagementServiceName
  description: apiManagementServiceName

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
  signInAudience: 'AzureADMyOrg'
}

resource apimServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
  displayName: apiManagementServiceName
  description: apiManagementServiceName

  appId: apimAppRegistration.appId
  appDisplayName: apiManagementServiceName
  appDescription: apiManagementServiceName
  
  accountEnabled: true
  appRoleAssignmentRequired: true

  owners: {
    relationships: [
      deployer().objectId
    ]
  }
  // servicePrincipalNames: apimAppRegistration.identifierUris
  // servicePrincipalType: 'string'
  // tags: [
  //   'string'
  // ]
}
