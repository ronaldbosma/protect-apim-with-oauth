//=============================================================================
// Client App Registration, Service Principal and App Role Assignments
//=============================================================================

targetScope = 'subscription'

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

@description('The tags to associate with the resource')
param tags object

@description('The name of the API Management app registration')
param apimAppRegistrationName string

@description('The name of the client')
param clientName string

//=============================================================================
// Existing Resources
//=============================================================================

resource apimAppRegistration 'Microsoft.Graph/applications@v1.0' existing = {
  uniqueName: apimAppRegistrationName
}

resource apimServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' existing = {
  appId: apimAppRegistration.appId
}

//=============================================================================
// Functions
//=============================================================================

func getAppRoleIdByValue(appRoles array, value string) string =>
  first(filter(appRoles, (role) => role.value == value)).id

//=============================================================================
// Resources
//=============================================================================

resource clientAppRegistration 'Microsoft.Graph/applications@v1.0' = {
  tags: helpers.flattenTags(tags)
  
  uniqueName: clientName
  displayName: clientName

  owners: {
    relationships: [
      deployer().objectId
    ]
  }
}

resource clientServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: clientAppRegistration.appId
}

resource assignSampleRead 'Microsoft.Graph/appRoleAssignedTo@v1.0' = {
  principalId: clientServicePrincipal.id
  resourceId: apimServicePrincipal.id
  appRoleId: getAppRoleIdByValue(apimAppRegistration.appRoles, 'Sample.Read')
}

resource assignSampleWrite 'Microsoft.Graph/appRoleAssignedTo@v1.0' = {
  principalId: clientServicePrincipal.id
  resourceId: apimServicePrincipal.id
  appRoleId: getAppRoleIdByValue(apimAppRegistration.appRoles, 'Sample.Write')
}
