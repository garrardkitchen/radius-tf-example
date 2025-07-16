# What does this do?

It deploys a radius app that creates an azure storage account using a terraform recipe...or tries too!

# Getting started

Please follow these 6 steps:

**Step 1** - Create app reg and set defaults

```bash
WORKSTREAM="gpk"
ENV="dev"
SP_OUTPUT=$(az ad sp create-for-rbac -n radius --output json)
RESOURCE_GROUP="rg-$WORKSTREAM-$ENV"
STORAGE_ACCOUNT_NAME="$WORKSTREAM$(date +%d%m%Y)$ENV"
LOCATION="uksouth"
az group create --location $LOCATION --resource-group $RESOURCE_GROUP
```

**Step 2** - capture app reg and insert into env vars

```bash
ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
ARM_CLIENT_ID=$(echo "$SP_OUTPUT" | jq -r '.appId')
ARM_CLIENT_SECRET=$(echo "$SP_OUTPUT" | jq -r '.password')
ARM_TENANT_ID=$(echo "$SP_OUTPUT" | jq -r '.tenant')

export ARM_CLIENT_ID="$ARM_CLIENT_ID"
export ARM_CLIENT_SECRET="$ARM_CLIENT_SECRET"
export ARM_SUBSCRIPTION_ID="$ARM_SUBSCRIPTION_ID"
export ARM_TENANT_ID="$ARM_TENANT_ID"
```

**Step 3** - Create azure provider credentials

```bash
rad credential register azure sp \
    --client-id "$ARM_CLIENT_ID" \
    --client-secret "$ARM_CLIENT_SECRET" \
    --tenant-id "$ARM_TENANT_ID" 
```

**Step 4** - create the azStorageAccount radius.resource custom resource type and publish extention to use in vscode

```bash
rad resource-type create azStorageAccount -f types.yaml
rad bicep publish-extension -f types.yaml --target radiusResources.tgz
```

**Step 5** - Create environment (terraform provider & terraform recipe)

```bash
rad deploy .env/dev.bicep --parameters tenantId=$ARM_TENANT_ID \
 --parameters clientId=$ARM_CLIENT_ID \
 --parameters clientSecret=$ARM_CLIENT_SECRET \
 --parameters subscriptionId=$ARM_SUBSCRIPTION_ID \
 --parameters resourceGroupName=$RESOURCE_GROUP
```

**Step 6** - Deploy app

```bash
rad deploy app.bicep -e dev \
   --parameters location=$LOCATION   
```

---

# CLI cmds

**Unregister recipe**:

```bash
rad recipe unregister default  --resource-type Radius.Resources/azStorageAccount --environment $ENV
```

**Unregister azure provider credential**:

```bash
rad credential unregister azure 
```