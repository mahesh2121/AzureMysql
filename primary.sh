#!/bin/bash

# Azure MySQL Flexible Server Prerequisites Setup Script
# This script creates all required resources for the AVM MySQL Flexible Server module

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration variables
RESOURCE_GROUP="rg-mysql-flexible-01"
LOCATION="canada central"
VNET_NAME="vnet-mysql"
VNET_ADDRESS="10.0.0.0/16"
MYSQL_SUBNET_NAME="snet-mysql-delegated"
MYSQL_SUBNET_PREFIX="10.0.1.0/24"
PE_SUBNET_NAME="snet-privateendpoints"
PE_SUBNET_PREFIX="10.0.2.0/24"
KEY_VAULT_NAME="kv-mysql-$(date +%s)"
KEY_NAME="key-mysql-cmk"
USER_ASSIGNED_IDENTITY_NAME="id-mysql-cmk"
PRIVATE_DNS_ZONE_NAME="privatelink.mysql.database.azure.com"

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Azure CLI is installed
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if logged in
    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    print_info "Prerequisites check passed!"
}

# Create Resource Group
create_resource_group() {
    print_info "Creating Resource Group: $RESOURCE_GROUP..."
    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --output none
    print_info "Resource Group created successfully!"
}

# Create Virtual Network
create_vnet() {
    print_info "Creating Virtual Network: $VNET_NAME..."
    az network vnet create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$VNET_NAME" \
        --address-prefix "$VNET_ADDRESS" \
        --location "$LOCATION" \
        --output none
    print_info "Virtual Network created successfully!"
}

# Create MySQL Delegated Subnet
create_mysql_subnet() {
    print_info "Creating MySQL delegated subnet: $MYSQL_SUBNET_NAME..."
    az network vnet subnet create \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "$VNET_NAME" \
        --name "$MYSQL_SUBNET_NAME" \
        --address-prefixes "$MYSQL_SUBNET_PREFIX" \
        --delegations "Microsoft.DBforMySQL/flexibleServers" \
        --output none
    print_info "MySQL delegated subnet created successfully!"
}

# Create Private Endpoint Subnet
create_pe_subnet() {
    print_info "Creating Private Endpoint subnet: $PE_SUBNET_NAME..."
    az network vnet subnet create \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "$VNET_NAME" \
        --name "$PE_SUBNET_NAME" \
        --address-prefixes "$PE_SUBNET_PREFIX" \
        --output none
    print_info "Private Endpoint subnet created successfully!"
}

# Create User Assigned Managed Identity
create_identity() {
    print_info "Creating User Assigned Managed Identity: $USER_ASSIGNED_IDENTITY_NAME..."
    az identity create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$USER_ASSIGNED_IDENTITY_NAME" \
        --location "$LOCATION" \
        --output none
    print_info "User Assigned Managed Identity created successfully!"
}

# Create Key Vault
create_key_vault() {
    print_info "Creating Key Vault: $KEY_VAULT_NAME..."
    
    TENANT_ID=$(az account show --query tenantId -o tsv)
    CURRENT_USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
    
    az keyvault create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$KEY_VAULT_NAME" \
        --location "$LOCATION" \
        --enabled-for-disk-encryption true \
        --enable-purge-protection true \
        --enable-rbac-authorization false \
        --output none
    
    print_info "Key Vault created successfully!"
    
    # Set access policy for current user
    print_info "Setting Key Vault access policy for current user..."
    az keyvault set-policy \
        --name "$KEY_VAULT_NAME" \
        --object-id "$CURRENT_USER_OBJECT_ID" \
        --key-permissions get list create delete update import backup restore recover \
        --secret-permissions get list set delete backup restore recover \
        --certificate-permissions get list create delete update import \
        --output none
}

# Get Managed Identity details and set Key Vault access
configure_identity_access() {
    print_info "Configuring Managed Identity access to Key Vault..."
    
    IDENTITY_PRINCIPAL_ID=$(az identity show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$USER_ASSIGNED_IDENTITY_NAME" \
        --query principalId -o tsv)
    
    # Wait a bit for identity to propagate
    sleep 10
    
    az keyvault set-policy \
        --name "$KEY_VAULT_NAME" \
        --object-id "$IDENTITY_PRINCIPAL_ID" \
        --key-permissions get unwrapKey wrapKey \
        --output none
    
    print_info "Managed Identity access configured successfully!"
}

# Create Key for CMK
create_cmk_key() {
    print_info "Creating CMK key: $KEY_NAME..."
    az keyvault key create \
        --vault-name "$KEY_VAULT_NAME" \
        --name "$KEY_NAME" \
        --kty RSA \
        --size 2048 \
        --ops encrypt decrypt sign verify wrapKey unwrapKey \
        --output none
    print_info "CMK key created successfully!"
}

# Create Private DNS Zone
create_private_dns_zone() {
    print_info "Creating Private DNS Zone: $PRIVATE_DNS_ZONE_NAME..."
    az network private-dns zone create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$PRIVATE_DNS_ZONE_NAME" \
        --output none
    print_info "Private DNS Zone created successfully!"
}

# Link Private DNS Zone to VNet
link_dns_to_vnet() {
    print_info "Linking Private DNS Zone to VNet..."
    az network private-dns link vnet create \
        --resource-group "$RESOURCE_GROUP" \
        --zone-name "$PRIVATE_DNS_ZONE_NAME" \
        --name "link-${VNET_NAME}" \
        --virtual-network "$VNET_NAME" \
        --registration-enabled false \
        --output none
    print_info "Private DNS Zone linked to VNet successfully!"
}

# Output resource IDs
output_resource_ids() {
    print_info "Gathering resource IDs..."
    
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    VNET_ID=$(az network vnet show --resource-group "$RESOURCE_GROUP" --name "$VNET_NAME" --query id -o tsv)
    MYSQL_SUBNET_ID=$(az network vnet subnet show --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET_NAME" --name "$MYSQL_SUBNET_NAME" --query id -o tsv)
    PE_SUBNET_ID=$(az network vnet subnet show --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET_NAME" --name "$PE_SUBNET_NAME" --query id -o tsv)
    IDENTITY_ID=$(az identity show --resource-group "$RESOURCE_GROUP" --name "$USER_ASSIGNED_IDENTITY_NAME" --query id -o tsv)
    KEY_VAULT_ID=$(az keyvault show --name "$KEY_VAULT_NAME" --query id -o tsv)
    KEY_ID=$(az keyvault key show --vault-name "$KEY_VAULT_NAME" --name "$KEY_NAME" --query key.kid -o tsv)
    DNS_ZONE_ID=$(az network private-dns zone show --resource-group "$RESOURCE_GROUP" --name "$PRIVATE_DNS_ZONE_NAME" --query id -o tsv)
    
    # Create output file
    OUTPUT_FILE="mysql_resources_output.txt"
    cat > "$OUTPUT_FILE" << EOF
============================================
Azure MySQL Flexible Server Prerequisites
============================================

Resource Group:
  Name: $RESOURCE_GROUP
  Location: $LOCATION

Virtual Network:
  Name: $VNET_NAME
  ID: $VNET_ID
  Address Space: $VNET_ADDRESS

MySQL Delegated Subnet:
  Name: $MYSQL_SUBNET_NAME
  ID: $MYSQL_SUBNET_ID
  Address Prefix: $MYSQL_SUBNET_PREFIX

Private Endpoint Subnet:
  Name: $PE_SUBNET_NAME
  ID: $PE_SUBNET_ID
  Address Prefix: $PE_SUBNET_PREFIX

User Assigned Managed Identity:
  Name: $USER_ASSIGNED_IDENTITY_NAME
  ID: $IDENTITY_ID

Key Vault:
  Name: $KEY_VAULT_NAME
  ID: $KEY_VAULT_ID

CMK Key:
  Name: $KEY_NAME
  ID: $KEY_ID

Private DNS Zone:
  Name: $PRIVATE_DNS_ZONE_NAME
  ID: $DNS_ZONE_ID

============================================
Terraform Variables (copy to your .tfvars)
============================================

resource_group_name           = "$RESOURCE_GROUP"
location                      = "$LOCATION"
delegated_subnet_id           = "$MYSQL_SUBNET_ID"
private_endpoint_subnet_id    = "$PE_SUBNET_ID"
managed_identity_id           = "$IDENTITY_ID"
key_vault_key_id              = "$KEY_ID"
private_dns_zone_id           = "$DNS_ZONE_ID"

============================================
EOF

    print_info "Resource IDs saved to: $OUTPUT_FILE"
    cat "$OUTPUT_FILE"
}

# Main execution
main() {
    print_info "Starting Azure MySQL Flexible Server prerequisites setup..."
    echo ""
    
    check_prerequisites
    create_resource_group
    create_vnet
    create_mysql_subnet
    create_pe_subnet
    create_identity
    create_key_vault
    configure_identity_access
    create_cmk_key
    create_private_dns_zone
    link_dns_to_vnet
    output_resource_ids
    
    echo ""
    print_info "Setup completed successfully!"
    print_info "You can now use these resources with the Azure MySQL Flexible Server module."
    print_info "Resource details have been saved to: mysql_resources_output.txt"
}

# Run main function
main