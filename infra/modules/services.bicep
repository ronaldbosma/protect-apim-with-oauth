//=============================================================================
// Azure services that are deployed with this template
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import * as settings from '../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('Location to use for all resources')
param location string

@description('The tags to associate with the resource')
param tags object

@description('The settings for the API Management Service that will be created')
param apiManagementSettings settings.apiManagementSettingsType

@description('The settings for the App Insights instance that will be created')
param appInsightsSettings settings.appInsightsSettingsType

@description('The settings for the Function App that will be created')
param functionAppSettings settings.functionAppSettingsType

@description('The settings for the Logic App that will be created')
param logicAppSettings settings.logicAppSettingsType

@description('The name of the Storage Account that will be created')
param storageAccountName string

//=============================================================================
// Resources
//=============================================================================

module storageAccount 'services/storage-account.bicep' = {
  name: 'storageAccount'
  params: {
    location: location
    tags: tags
    storageAccountName: storageAccountName
  }
}

module appInsights 'services/app-insights.bicep' = {
  name: 'appInsights'
  params: {
    location: location
    tags: tags
    appInsightsSettings: appInsightsSettings
  }
}

module apiManagement 'services/api-management.bicep' = {
  name: 'apiManagement'
  params: {
    location: location
    tags: tags
    apiManagementSettings: apiManagementSettings
    appInsightsName: appInsightsSettings.appInsightsName
  }
  dependsOn: [
    appInsights
  ]
}

module functionApp 'services/function-app.bicep' = {
  name: 'functionApp'
  params: {
    location: location
    tags: tags
    functionAppSettings: functionAppSettings
    apiManagementSettings: apiManagementSettings
    appInsightsName: appInsightsSettings.appInsightsName
    storageAccountName: storageAccountName
  }
  dependsOn: [
    appInsights
    storageAccount
  ]
}

module logicApp 'services/logic-app.bicep' = {
  name: 'logicApp'
  params: {
    location: location
    tags: tags
    logicAppSettings: logicAppSettings
    apiManagementSettings: apiManagementSettings
    appInsightsName: appInsightsSettings.appInsightsName
    storageAccountName: storageAccountName
  }
  dependsOn: [
    appInsights
    storageAccount
  ]
}
