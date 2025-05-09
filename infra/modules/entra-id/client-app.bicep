//=============================================================================
// Client App Registration & Service Principal
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

@description('The tags to associate with the resource')
param tags object

@description('The name of the API Management application')
param apiManagementAppName string

@description('The name of the client')
param clientName string

//=============================================================================
// Existing Resources
//=============================================================================

resource apimAppRegistration 'Microsoft.Graph/applications@v1.0' existing = {
  uniqueName: apiManagementAppName
}

//=============================================================================
// Resources
//=============================================================================

resource clientAppRegistration 'Microsoft.Graph/applications@v1.0' = {
  tags: helpers.flattenTags(tags)
  
  uniqueName: clientName
  displayName: clientName
  description: clientName
  web: {
    implicitGrantSettings: {
      enableIdTokenIssuance: true
    }
  }
  requiredResourceAccess: [
    {
      resourceAppId: apimAppRegistration.appId
      resourceAccess: [
        {
          id: apimAppRegistration.appRoles[0].id
          type: 'Role'
        }
        {
          id: apimAppRegistration.appRoles[1].id
          type: 'Role'
        }
      ]
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
  displayName: clientName
  description: clientName

  appId: clientAppRegistration.appId
  // appDisplayName: clientAppRegistration.displayName
  // appDescription: clientAppRegistration.description
  
  accountEnabled: true

  owners: {
    relationships: [
      deployer().objectId
    ]
  }
}
