// Azure Static Website Infrastructure for Stey
// With Azure CDN for custom domain HTTPS support

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

// CDN Profile
resource cdnProfile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: '${prefix}-${environment}-cdn'
  location: 'global'
  sku: {
    name: 'Standard_Microsoft'
  }
}

// CDN Endpoint
resource cdnEndpoint 'Microsoft.Cdn/profiles/endpoints@2023-05-01' = {
  parent: cdnProfile
  name: '${prefix}-${environment}'
  location: 'global'
  properties: {
    originHostHeader: replace(replace(storageAccount.properties.primaryEndpoints.web, 'https://', ''), '/', '')
    isHttpAllowed: false
    isHttpsAllowed: true
    queryStringCachingBehavior: 'IgnoreQueryString'
    optimizationType: 'GeneralWebDelivery'
    origins: [
      {
        name: 'storage-origin'
        properties: {
          hostName: replace(replace(storageAccount.properties.primaryEndpoints.web, 'https://', ''), '/', '')
          httpPort: 80
          httpsPort: 443
          originHostHeader: replace(replace(storageAccount.properties.primaryEndpoints.web, 'https://', ''), '/', '')
          priority: 1
          weight: 1000
          enabled: true
        }
      }
    ]
    deliveryPolicy: {
      rules: [
        {
          name: 'EnforceHTTPS'
          order: 1
          conditions: [
            {
              name: 'RequestScheme'
              parameters: {
                typeName: 'DeliveryRuleRequestSchemeConditionParameters'
                matchValues: ['HTTP']
                operator: 'Equal'
                negateCondition: false
              }
            }
          ]
          actions: [
            {
              name: 'UrlRedirect'
              parameters: {
                typeName: 'DeliveryRuleUrlRedirectActionParameters'
                redirectType: 'Found'
                destinationProtocol: 'Https'
              }
            }
          ]
        }
      ]
    }
  }
}

// Outputs
output storageAccountName string = storageAccount.name
output staticWebsiteUrl string = storageAccount.properties.primaryEndpoints.web
output cdnEndpointHostname string = cdnEndpoint.properties.hostName
output cdnEndpointUrl string = 'https://${cdnEndpoint.properties.hostName}'
output cdnProfileName string = cdnProfile.name
output cdnEndpointName string = cdnEndpoint.name
