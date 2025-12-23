// Azure Static Website Infrastructure for Stey
// Simplified version - static website enabled via CLI in workflow

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'prod'

@description('Azure region')
param location string = resourceGroup().location

// Naming
var prefix = 'stey'
var resourceToken = uniqueString(resourceGroup().id)
var storageAccountName = take('${prefix}${environment}${resourceToken}', 24)

// Storage Account for Static Website
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
  }
}

// Outputs
output storageAccountName string = storageAccount.name
output resourceGroupName string = resourceGroup().name
