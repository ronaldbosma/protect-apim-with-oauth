//=============================================================================
// Client App Registration with Service Principal
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

@description('The name of the client app registration')
param clientAppRegistrationName string

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
  
  uniqueName: clientAppRegistrationName
  displayName: clientAppRegistrationName

  owners: {
    relationships: [
      deployer().objectId
    ]
  }
}

resource clientServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: clientAppRegistration.appId
}
