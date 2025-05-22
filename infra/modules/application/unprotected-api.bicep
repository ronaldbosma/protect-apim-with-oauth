//=============================================================================
// Unprotected API in API Management
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the API Management service')
param apiManagementServiceName string

//=============================================================================
// Existing resources
//=============================================================================

resource apiManagementService 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apiManagementServiceName
}

//=============================================================================
// Resources
//=============================================================================

// Named Values

resource oauthScopeNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-06-01-preview' = {
  name: 'oauth-scope'
  parent: apiManagementService
  properties: {
    displayName: 'oauth-scope'
    value: 'api://${apiManagementServiceName}'
  }
}

// API

resource unprotectedApi 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  name: 'unprotected-api'
  parent: apiManagementService
  properties: {
    displayName: 'Unprotected API'
    path: 'unprotected'
    protocols: [ 
      'https' 
    ]
    subscriptionRequired: false // API is unprotected
  }
  
  resource policies 'policies' = {
    name: 'policy'
    properties: {
      format: 'rawxml'
      value: loadTextContent('unprotected-api.xml')
    }
  }

  resource getOperation 'operations' = {
    name: 'get'
    properties: {
      displayName: 'Get'
      method: 'GET'
      urlTemplate: '/'
    }
  }

  resource postOperation 'operations' = {
    name: 'post'
    properties: {
      displayName: 'Post'
      method: 'POST'
      urlTemplate: '/'
    }
  }

  resource deleteOperation 'operations' = {
    name: 'delete'
    properties: {
      displayName: 'Delete'
      method: 'DELETE'
      urlTemplate: '/'
    }
  }
}
