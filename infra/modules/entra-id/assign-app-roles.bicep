//=============================================================================
// Assign App Roles to the Client App Registration
//=============================================================================

targetScope = 'subscription'

//=============================================================================
// Extensions
//=============================================================================

extension microsoftGraphV1

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the API Management app registration')
param apimAppRegistrationName string

@description('The name of the client app registration')
param clientAppRegistrationName string

//=============================================================================
// Existing Resources
//=============================================================================

resource apimAppRegistration 'Microsoft.Graph/applications@v1.0' existing = {
  uniqueName: apimAppRegistrationName
}

resource apimServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' existing = {
  appId: apimAppRegistration.appId
}

resource clientAppRegistration 'Microsoft.Graph/applications@v1.0' existing = {
  uniqueName: clientAppRegistrationName
}

resource clientServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' existing = {
  appId: clientAppRegistration.appId
}

//=============================================================================
// Functions
//=============================================================================

func getAppRoleIdByValue(appRoles array, value string) string =>
  first(filter(appRoles, (role) => role.value == value)).id

//=============================================================================
// Variables
//=============================================================================

var rolesToAssign = [
  'Sample.Read'
  'Sample.Write'
]

//=============================================================================
// Resources
//=============================================================================

resource assignAppRole 'Microsoft.Graph/appRoleAssignedTo@v1.0' = [for role in rolesToAssign: {
  resourceId: apimServicePrincipal.id
  appRoleId: getAppRoleIdByValue(apimAppRegistration.appRoles, role)
  principalId: clientServicePrincipal.id
}]
