# MySQL Flexible Server - Prerequisites Documentation

## Overview
This document outlines all resources that must be created **BEFORE** deploying the MySQL Flexible Server using the provided Terraform configuration.

---

## Prerequisites Summary Table

| # | Resource Type | Resource Name | Required | Purpose | Created By |
|---|--------------|---------------|----------|---------|------------|
| 1 | Resource Group | `rg-mysql-flexible-01` | ✅ Yes | Container for all MySQL resources | Manual/Terraform |
| 2 | Virtual Network | `vnet-mysql` | ✅ Yes | Network isolation and connectivity | Manual/Terraform |
| 3 | Delegated Subnet | `snet-mysql-delegated` | ✅ Yes | Subnet delegated to MySQL service | Manual/Terraform |
| 4 | Private DNS Zone | `privatelink.mysql.database.azure.com` | ✅ Yes | Private DNS resolution for MySQL | Manual/Terraform |
| 5 | DNS Zone VNet Link | `vnet-link` | ✅ Yes | Links DNS zone to VNet | Manual/Terraform |
| 6 | User-Assigned Identity | `id-mysql-cmk` | ✅ Yes (for CMK) | Identity for CMK encryption | Manual/Terraform |
| 7 | Key Vault | `kv-mysql-1764745586` | ✅ Yes (for CMK) | Stores encryption keys | Manual/Terraform |
| 8 | Key Vault Key | `key-mysql-cmk` | ✅ Yes (for CMK) | Encryption key for data | Manual/Terraform |
| 9 | Key Vault Access Policy | N/A | ✅ Yes (for CMK) | Grants identity access to keys | Manual/Terraform |

---

## Detailed Prerequisites

### 1. Resource Group

**What it is:** Container that holds related Azure resources.

**Configuration from tfvars:**
```hcl
resource_group_name = "rg-mysql-flexible-01"
location            = "canada central"
```

**Azure CLI Command:**
```bash
az group create \
  --name "rg-mysql-flexible-01" \
  --location "canadacentral"
```

**Why Required:** All Azure resources must be deployed into a resource group.

---

### 2. Virtual Network (VNet)

**What it is:** Isolated network in Azure that provides network segmentation.

**Configuration Requirements:**
- **Name:** `vnet-mysql`
- **Address Space:** Minimum `/16` (e.g., `10.0.0.0/16`)
- **Location:** Same as resource group

**Azure CLI Command:**
```bash
az network vnet create \
  --name "vnet-mysql" \
  --resource-group "rg-mysql-flexible-01" \
  --location "canadacentral" \
  --address-prefixes "10.0.0.0/16"
```

**Why Required:** MySQL Flexible Server requires a VNet for private networking.

---

### 3. Delegated Subnet

**What it is:** A subnet specifically delegated to MySQL Flexible Server service.

**Configuration from tfvars:**
```hcl
delegated_subnet_id = "/subscriptions/1b48eaaa-febf-4c0d-9d42-5b36ef4d7ac1/resourceGroups/rg-mysql-flexible-01/providers/Microsoft.Network/virtualNetworks/vnet-mysql/subnets/snet-mysql-delegated"
```

**Requirements:**
- **Address Prefix:** Minimum `/28` (16 IPs) for single server, `/27` (32 IPs) recommended for HA
- **Delegation:** Must be delegated to `Microsoft.DBforMySQL/flexibleServers`
- **Cannot be shared:** This subnet cannot be used by other services

**Azure CLI Command:**
```bash
az network vnet subnet create \
  --name "snet-mysql-delegated" \
  --resource-group "rg-mysql-flexible-01" \
  --vnet-name "vnet-mysql" \
  --address-prefixes "10.0.1.0/27" \
  --delegations "Microsoft.DBforMySQL/flexibleServers" \
  --service-endpoints "Microsoft.Storage"
```

**Why Required:** MySQL Flexible Server injects network interfaces into this subnet for private connectivity.

**⚠️ Critical Notes:**
- Subnet must be delegated BEFORE MySQL server creation
- Delegation cannot be added after subnet creation if resources exist
- Minimum 16 IP addresses required (after Azure reserved IPs)

---

### 4. Private DNS Zone

**What it is:** Private DNS zone for resolving MySQL server's private endpoint.

**Configuration from tfvars:**
```hcl
private_dns_zone_id = "/subscriptions/1b48eaaa-febf-4c0d-9d42-5b36ef4d7ac1/resourceGroups/rg-mysql-flexible-01/providers/Microsoft.Network/privateDnsZones/privatelink.mysql.database.azure.com"
```

**Requirements:**
- **Name:** MUST be exactly `privatelink.mysql.database.azure.com`
- **Resource Group:** Can be same or different from MySQL resource group

**Azure CLI Command:**
```bash
az network private-dns zone create \
  --name "privatelink.mysql.database.azure.com" \
  --resource-group "rg-mysql-flexible-01"
```

**Why Required:** Enables DNS resolution for MySQL server's private FQDN within the VNet.

---

### 5. Private DNS Zone VNet Link

**What it is:** Links the Private DNS Zone to your Virtual Network.

**Requirements:**
- Links DNS zone to VNet
- Enables DNS resolution within VNet

**Azure CLI Command:**
```bash
az network private-dns link vnet create \
  --name "vnet-link-mysql" \
  --resource-group "rg-mysql-flexible-01" \
  --zone-name "privatelink.mysql.database.azure.com" \
  --virtual-network "vnet-mysql" \
  --registration-enabled false
```

**Why Required:** Without this link, VMs in the VNet cannot resolve the MySQL server's private DNS name.

---

### 6. User-Assigned Managed Identity (for CMK)

**What it is:** Azure identity used by MySQL to access Key Vault for encryption keys.

**Configuration from tfvars:**
```hcl
managed_identities = {
  user_assigned_resource_ids = [
    "/subscriptions/1b48eaaa-febf-4c0d-9d42-5b36ef4d7ac1/resourceGroups/rg-mysql-flexible-01/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-mysql-cmk"
  ]
}
```

**Azure CLI Command:**
```bash
az identity create \
  --name "id-mysql-cmk" \
  --resource-group "rg-mysql-flexible-01" \
  --location "canadacentral"

# Get the principal ID (needed for Key Vault access policy)
IDENTITY_PRINCIPAL_ID=$(az identity show \
  --name "id-mysql-cmk" \
  --resource-group "rg-mysql-flexible-01" \
  --query principalId -o tsv)

echo "Identity Principal ID: $IDENTITY_PRINCIPAL_ID"
```

**Why Required:** MySQL server uses this identity to retrieve encryption keys from Key Vault.

---

### 7. Key Vault

**What it is:** Secure storage for encryption keys, secrets, and certificates.

**Configuration from tfvars:**
```hcl
customer_managed_key = {
  key_vault_key_id = "https://kv-mysql-1764745586.vault.azure.net/keys/key-mysql-cmk/16f36cce789c4be9969e19a84af66042"
}
```

**Requirements:**
- **Purge Protection:** Must be enabled (cannot be disabled once enabled)
- **Soft Delete:** Enabled by default (7-90 day retention)
- **SKU:** Standard or Premium (Premium required for HSM-backed keys)

**Azure CLI Command:**
```bash
az keyvault create \
  --name "kv-mysql-1764745586" \
  --resource-group "rg-mysql-flexible-01" \
  --location "canadacentral" \
  --sku "premium" \
  --enable-purge-protection true \
  --retention-days 7
```

**Why Required:** Stores the Customer-Managed Key (CMK) used for data encryption at rest.

---

### 8. Key Vault Key

**What it is:** RSA encryption key used by MySQL for data encryption.

**Configuration from tfvars:**
```hcl
key_vault_key_id = "https://kv-mysql-1764745586.vault.azure.net/keys/key-mysql-cmk/16f36cce789c4be9969e19a84af66042"
```

**Requirements:**
- **Key Type:** RSA
- **Key Size:** 2048, 3072, or 4096 bits
- **Key Operations:** wrapKey, unwrapKey

**Azure CLI Command:**
```bash
az keyvault key create \
  --name "key-mysql-cmk" \
  --vault-name "kv-mysql-1764745586" \
  --kty "RSA" \
  --size 2048 \
  --ops wrapKey unwrapKey encrypt decrypt
```

**Why Required:** This is the actual encryption key used to encrypt MySQL data at rest.

---

### 9. Key Vault Access Policy

**What it is:** Grants the managed identity permission to access encryption keys.

**Requirements:**
- Grant `Get`, `WrapKey`, `UnwrapKey` permissions to managed identity
- Also grant permissions to your user account for key management

**Azure CLI Commands:**
```bash
# Get the managed identity principal ID
IDENTITY_PRINCIPAL_ID=$(az identity show \
  --name "id-mysql-cmk" \
  --resource-group "rg-mysql-flexible-01" \
  --query principalId -o tsv)

# Grant managed identity access to Key Vault
az keyvault set-policy \
  --name "kv-mysql-1764745586" \
  --object-id $IDENTITY_PRINCIPAL_ID \
  --key-permissions get wrapKey unwrapKey

# Grant your user account access (for key management)
CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)

az keyvault set-policy \
  --name "kv-mysql-1764745586" \
  --object-id $CURRENT_USER_ID \
  --key-permissions get list create delete update recover purge
```

**Why Required:** Without proper permissions, MySQL cannot access the encryption key, and deployment will fail.

---

## Prerequisites Validation Checklist

Before running `terraform apply`, verify all prerequisites:

| Step | Validation Command | Expected Result |
|------|-------------------|-----------------|
| 1. Resource Group | `az group show --name "rg-mysql-flexible-01"` | Returns group details |
| 2. VNet | `az network vnet show --name "vnet-mysql" --resource-group "rg-mysql-flexible-01"` | Returns VNet details |
| 3. Delegated Subnet | `az network vnet subnet show --name "snet-mysql-delegated" --vnet-name "vnet-mysql" --resource-group "rg-mysql-flexible-01" --query "delegations"` | Shows MySQL delegation |
| 4. Private DNS Zone | `az network private-dns zone show --name "privatelink.mysql.database.azure.com" --resource-group "rg-mysql-flexible-01"` | Returns DNS zone details |
| 5. DNS VNet Link | `az network private-dns link vnet list --zone-name "privatelink.mysql.database.azure.com" --resource-group "rg-mysql-flexible-01"` | Shows VNet link |
| 6. Managed Identity | `az identity show --name "id-mysql-cmk" --resource-group "rg-mysql-flexible-01"` | Returns identity details |
| 7. Key Vault | `az keyvault show --name "kv-mysql-1764745586"` | Returns vault details |
| 8. Key Vault Key | `az keyvault key show --name "key-mysql-cmk" --vault-name "kv-mysql-1764745586"` | Returns key details |
| 9. Access Policy | `az keyvault show --name "kv-mysql-1764745586" --query "properties.accessPolicies[?objectId=='$IDENTITY_PRINCIPAL_ID']"` | Returns access policy |

---

## Complete Prerequisites Creation Script

```bash
#!/bin/bash
################################################################################
# Complete Prerequisites Creation Script for MySQL Flexible Server
################################################################################

# Configuration Variables
SUBSCRIPTION_ID="1b48eaaa-febf-4c0d-9d42-5b36ef4d7ac1"
RESOURCE_GROUP="rg-mysql-flexible-01"
LOCATION="canadacentral"
VNET_NAME="vnet-mysql"
SUBNET_NAME="snet-mysql-delegated"
DNS_ZONE="privatelink.mysql.database.azure.com"
IDENTITY_NAME="id-mysql-cmk"
KV_NAME="kv-mysql-1764745586"
KEY_NAME="key-mysql-cmk"

echo "================================================"
echo "MySQL Flexible Server Prerequisites Setup"
echo "================================================"

# Set subscription
az account set --subscription $SUBSCRIPTION_ID

# Step 1: Create Resource Group
echo -e "\n[1/9] Creating Resource Group..."
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --output table

# Step 2: Create Virtual Network
echo -e "\n[2/9] Creating Virtual Network..."
az network vnet create \
  --name $VNET_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --address-prefixes "10.0.0.0/16" \
  --output table

# Step 3: Create Delegated Subnet for MySQL
echo -e "\n[3/9] Creating Delegated Subnet..."
az network vnet subnet create \
  --name $SUBNET_NAME \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --address-prefixes "10.0.1.0/27" \
  --delegations "Microsoft.DBforMySQL/flexibleServers" \
  --service-endpoints "Microsoft.Storage" \
  --output table

# Step 4: Create Private DNS Zone
echo -e "\n[4/9] Creating Private DNS Zone..."
az network private-dns zone create \
  --name $DNS_ZONE \
  --resource-group $RESOURCE_GROUP \
  --output table

# Step 5: Link Private DNS Zone to VNet
echo -e "\n[5/9] Linking Private DNS Zone to VNet..."
az network private-dns link vnet create \
  --name "vnet-link-mysql" \
  --resource-group $RESOURCE_GROUP \
  --zone-name $DNS_ZONE \
  --virtual-network $VNET_NAME \
  --registration-enabled false \
  --output table

# Step 6: Create User-Assigned Managed Identity
echo -e "\n[6/9] Creating Managed Identity..."
az identity create \
  --name $IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --output table

# Get Identity Principal ID
IDENTITY_PRINCIPAL_ID=$(az identity show \
  --name $IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --query principalId -o tsv)

echo "Identity Principal ID: $IDENTITY_PRINCIPAL_ID"

# Step 7: Create Key Vault
echo -e "\n[7/9] Creating Key Vault..."
az keyvault create \
  --name $KV_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku "premium" \
  --enable-purge-protection true \
  --retention-days 7 \
  --output table

# Step 8: Set Access Policy for Managed Identity
echo -e "\n[8/9] Setting Key Vault Access Policy for Managed Identity..."
az keyvault set-policy \
  --name $KV_NAME \
  --object-id $IDENTITY_PRINCIPAL_ID \
  --key-permissions get wrapKey unwrapKey \
  --output table

# Set Access Policy for Current User
CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)
echo "Current User Object ID: $CURRENT_USER_ID"

az keyvault set-policy \
  --name $KV_NAME \
  --object-id $CURRENT_USER_ID \
  --key-permissions get list create delete update recover purge \
  --output table

# Step 9: Create Key Vault Key
echo -e "\n[9/9] Creating Key Vault Key..."
az keyvault key create \
  --name $KEY_NAME \
  --vault-name $KV_NAME \
  --kty "RSA" \
  --size 2048 \
  --ops wrapKey unwrapKey encrypt decrypt \
  --output table

# Get Key ID
KEY_ID=$(az keyvault key show \
  --name $KEY_NAME \
  --vault-name $KV_NAME \
  --query key.kid -o tsv)

echo -e "\n================================================"
echo "Prerequisites Setup Complete!"
echo "================================================"
echo ""
echo "Resource IDs for terraform.tfvars:"
echo "-----------------------------------"

# Get Subnet ID
SUBNET_ID=$(az network vnet subnet show \
  --name $SUBNET_NAME \
  --vnet-name $VNET_NAME \
  --resource-group $RESOURCE_GROUP \
  --query id -o tsv)

# Get DNS Zone ID
DNS_ZONE_ID=$(az network private-dns zone show \
  --name $DNS_ZONE \
  --resource-group $RESOURCE_GROUP \
  --query id -o tsv)

# Get Identity ID
IDENTITY_ID=$(az identity show \
  --name $IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --query id -o tsv)

echo "delegated_subnet_id = \"$SUBNET_ID\""
echo ""
echo "private_dns_zone_id = \"$DNS_ZONE_ID\""
echo ""
echo "managed_identities = {"
echo "  user_assigned_resource_ids = ["
echo "    \"$IDENTITY_ID\""
echo "  ]"
echo "}"
echo ""
echo "customer_managed_key = {"
echo "  key_vault_key_id                  = \"$KEY_ID\""
echo "  primary_user_assigned_identity_id = \"$IDENTITY_ID\""
echo "}"
echo ""
echo "================================================"
echo "Next Steps:"
echo "1. Update your terraform.tfvars with the above values"
echo "2. Run: terraform init"
echo "3. Run: terraform plan"
echo "4. Run: terraform apply"
echo "================================================"
```

---

## Terraform Module Parameter Mapping

| tfvars Parameter | Prerequisite Resource | Resource ID Format |
|-----------------|----------------------|-------------------|
| `resource_group_name` | Resource Group | `rg-mysql-flexible-01` |
| `location` | Azure Region | `canadacentral` |
| `delegated_subnet_id` | Delegated Subnet | `/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}/subnets/{subnet}` |
| `private_dns_zone_id` | Private DNS Zone | `/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Network/privateDnsZones/privatelink.mysql.database.azure.com` |
| `managed_identities.user_assigned_resource_ids` | Managed Identity | `/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{identity}` |
| `customer_managed_key.key_vault_key_id` | Key Vault Key | `https://{keyvault}.vault.azure.net/keys/{key-name}/{version}` |
| `customer_managed_key.primary_user_assigned_identity_id` | Managed Identity | `/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{identity}` |

---

## Common Issues and Solutions

### Issue 1: Subnet Not Delegated
**Error:** `Subnet is not delegated to Microsoft.DBforMySQL/flexibleServers`

**Solution:**
```bash
az network vnet subnet update \
  --name "snet-mysql-delegated" \
  --vnet-name "vnet-mysql" \
  --resource-group "rg-mysql-flexible-01" \
  --delegations "Microsoft.DBforMySQL/flexibleServers"
```

### Issue 2: Key Vault Name Conflict
**Error:** `VaultAlreadyExists` or vault name is taken

**Solution:**
```bash
# Check for soft-deleted vault
az keyvault list-deleted --query "[?name=='kv-mysql-1764745586']"

# Purge if soft-deleted
az keyvault purge --name "kv-mysql-1764745586" --location "canadacentral"

# Wait 2-3 minutes, then recreate
```

### Issue 3: Insufficient Key Vault Permissions
**Error:** `The user, group or application does not have keys get permission`

**Solution:**
```bash
# Get identity principal ID
IDENTITY_ID=$(az identity show \
  --name "id-mysql-cmk" \
  --resource-group "rg-mysql-flexible-01" \
  --query principalId -o tsv)

# Update access policy
az keyvault set-policy \
  --name "kv-mysql-1764745586" \
  --object-id $IDENTITY_ID \
  --key-permissions get wrapKey unwrapKey
```

### Issue 4: Private DNS Zone Not Linked
**Error:** DNS resolution fails for MySQL server

**Solution:**
```bash
az network private-dns link vnet create \
  --name "vnet-link-mysql" \
  --resource-group "rg-mysql-flexible-01" \
  --zone-name "privatelink.mysql.database.azure.com" \
  --virtual-network "vnet-mysql" \
  --registration-enabled false
```

---

## Prerequisites Deployment Time

| Resource | Estimated Time | Notes |
|----------|---------------|-------|
| Resource Group | < 1 minute | Instant |
| Virtual Network | 1-2 minutes | Quick |
| Subnet | 1-2 minutes | Quick |
| Private DNS Zone | 1-2 minutes | Quick |
| DNS VNet Link | 1-2 minutes | Quick |
| Managed Identity | < 1 minute | Instant |
| Key Vault | 2-3 minutes | Includes soft-delete setup |
| Key Vault Key | < 1 minute | Instant |
| Access Policies | < 1 minute | Instant |
| **Total** | **10-15 minutes** | For all prerequisites |

---

## Next Steps After Prerequisites

1. ✅ Verify all resources created successfully
2. ✅ Update `terraform.tfvars` with resource IDs
3. ✅ Run `terraform init` to initialize providers
4. ✅ Run `terraform plan` to preview MySQL deployment
5. ✅ Run `terraform apply` to create MySQL Flexible Server
6. ✅ MySQL deployment takes 10-15 minutes (20-25 with HA)

---

## Summary

**Total Prerequisites Required:** 9 resources  
**Estimated Setup Time:** 10-15 minutes  
**Cost Impact:** ~$5-10/month for prerequisites (mainly Key Vault)  
**Deployment Method:** Azure CLI script or Terraform module

All prerequisites must be in place before running the MySQL Flexible Server Terraform module. The provided script automates the entire setup process.