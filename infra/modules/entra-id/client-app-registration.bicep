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
param name string

//=============================================================================
// Resources
//=============================================================================

resource clientAppRegistration 'Microsoft.Graph/applications@v1.0' = {
  // Add a 'HideApp' tag to hide the app from the end-users in the My Apps portal
  tags: concat(helpers.flattenTags(tags), ['HideApp'])
  
  uniqueName: name
  displayName: name
}

resource clientServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: clientAppRegistration.appId
}

//=============================================================================
// Resources
//=============================================================================

output appId string = clientAppRegistration.appId
