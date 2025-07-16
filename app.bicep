extension radius
extension radiusResources

@description('The Radius Application ID. Injected automatically by the rad CLI.')
param application string

@description('The Radius Environment ID. Injected automatically by the rad CLI.')
param environment string

// Storage account using Terraform recipe
resource storage 'Radius.Resources/azStorageAccount@2023-10-01-preview' = {
  name: 'terraform-storage-account'
  properties: {  
    environment: environment
    application: application
  }
}
    
   
resource demo 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'demo'
  properties: {
    application: application
    environment: environment
    container: {
      image: 'ghcr.io/radius-project/samples/demo:latest'
      ports: {
        web: {
          containerPort: 3000
        }
      }
      env: {
        STORAGE_ACCOUNT_NAME: {
          valueFrom: {
            secretRef: {
              source: storage.id
              key: 'storageAccountName'
            }
          }
        }
      }
    }
    connections: {
      storage: {
        source: storage.id
      }
    }
  }
}
