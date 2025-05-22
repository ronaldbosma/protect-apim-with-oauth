//=============================================================================
// Protected API in API Management
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the API Management service')
param apiManagementServiceName string

@description('The ID of the tenant')
param tenantId string

@description('The expected audience for the JWT token')
param jwtAudience string

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

resource tenantIdNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-06-01-preview' = {
  name: 'tenant-id'
  parent: apiManagementService
  properties: {
    displayName: 'tenant-id'
    value: tenantId
  }
}

resource jwtAudienceNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-06-01-preview' = {
  name: 'jwt-audience'
  parent: apiManagementService
  properties: {
    displayName: 'jwt-audience'
    value: jwtAudience
  }
}

// API

resource protectedApi 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  name: 'protected-api'
  parent: apiManagementService
  properties: {
    displayName: 'Protected API'
    path: 'protected'
    protocols: [ 
      'https' 
    ]
    subscriptionRequired: false // API is protected with OAuth
  }

  resource operations 'operations' = {
    name: 'get-jwt-token'
    properties: {
      displayName: 'Get JWT token'
      method: 'GET'
      urlTemplate: '/'
    }

    resource policies 'policies' = {
      name: 'policy'
      properties: {
        format: 'rawxml'
        value: loadTextContent('protected-api.get-jwt-token.xml')
      }
    }
  }

  dependsOn: [
    tenantIdNamedValue
    jwtAudienceNamedValue
  ]
}
