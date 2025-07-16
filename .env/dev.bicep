extension radius

@description('Azure tenant ID')
@secure()
param tenantId string

@description('Azure client ID (service principal)')
@secure()
param clientId string

@description('Azure client secret')
@secure()
param clientSecret string

@description('Azure subscription ID')
@secure()
param subscriptionId string

@description('Azure region')
param location string = resourceGroup().location

// Step 1: Define a secretStore resource for Azure credentials
resource azureSecretStore 'Applications.Core/secretStores@2023-10-01-preview' = {
  name: 'azure-secret-store'
  properties: {
    resource: 'azure-secrets-namespace/azure-secret-store'
    type: 'generic'
    data: {
      tenant_id: {
        value: tenantId
      }
      client_id: {
        value: clientId
      }
      client_secret: {
        value: clientSecret
      }
      subscription_id: {
        value: subscriptionId
      }
    }
  }
}

resource environment 'Applications.Core/environments@2023-10-01-preview' = {
  name: 'dev'
  properties: {
    compute: {
      kind: 'kubernetes' 
      namespace: 'default' 
    }
    providers: {
      azure: {
        scope: '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup().name}'
      }
    }
    recipeConfig: {
      terraform: {
        providers: {
          azurerm: [
            {
              features: {}
              secrets: {
                tenant_id: {
                  source: azureSecretStore.id
                  key: 'tenant_id'
                }
                client_id: {
                  source: azureSecretStore.id
                  key: 'client_id'
                }
                client_secret: {
                  source: azureSecretStore.id
                  key: 'client_secret'
                }
                subscription_id: {
                  source: azureSecretStore.id
                  key: 'subscription_id'
                }
              }
            }
          ]
        }
      }
      env: {
        AZURE_LOCATION: location
        AZURE_RESOURCE_GROUP: resourceGroup().name
      }
    }
    recipes: {
      'Radius.Resources/azStorageAccount': {
        default: {
          parameters: {
            location: location
          }
          templateKind: 'terraform'
          // Recipe template path
          templatePath: 'git::https://github.com/garrardkitchen/radius-tf-azure-sa'
        }
      }
    }
  }
}
