// Azure Static Website Infrastructure for Stey
// Best practices: Azure Verified Modules patterns, secure defaults

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'prod'

@description('Azure region')
param location string = resourceGroup().location

@description('Custom domain (optional)')
param customDomain string = ''

// Naming
var prefix = 'stey'
var resourceToken = uniqueString(resourceGroup().id)
var storageAccountName = '${prefix}${environment}${resourceToken}'

// Storage Account for Static Website
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: take(storageAccountName, 24) // Max 24 chars
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true // Required for static website
    allowSharedKeyAccess: true
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }

  resource blobService 'blobServices' = {
    name: 'default'

    resource webContainer 'containers' = {
      name: '$web'
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

// Enable Static Website (requires deployment script as it's a data plane operation)
resource deploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: '${prefix}-enable-static-website'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.50.0'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'STORAGE_ACCOUNT_NAME'
        value: storageAccount.name
      }
      {
        name: 'RESOURCE_GROUP'
        value: resourceGroup().name
      }
    ]
    scriptContent: '''
      az storage blob service-properties update \
        --account-name $STORAGE_ACCOUNT_NAME \
        --static-website \
        --index-document index.html \
        --404-document 404.html \
        --auth-mode login
    '''
  }
}

// CDN Profile for better performance and custom domain support
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
        {
          name: 'CacheStaticAssets'
          order: 2
          conditions: [
            {
              name: 'UrlFileExtension'
              parameters: {
                typeName: 'DeliveryRuleUrlFileExtensionMatchConditionParameters'
                operator: 'Equal'
                negateCondition: false
                matchValues: ['css', 'js', 'png', 'jpg', 'jpeg', 'gif', 'svg', 'woff', 'woff2', 'ttf', 'eot', 'ico']
              }
            }
          ]
          actions: [
            {
              name: 'CacheExpiration'
              parameters: {
                typeName: 'DeliveryRuleCacheExpirationActionParameters'
                cacheBehavior: 'Override'
                cacheType: 'All'
                cacheDuration: '7.00:00:00'
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
output cdnEndpointUrl string = 'https://${cdnEndpoint.properties.hostName}'
output cdnEndpointHostname string = cdnEndpoint.properties.hostName
output resourceGroupName string = resourceGroup().name
