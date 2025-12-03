# ============================================
# Required Variables
# ============================================

# Basic MySQL Server Configuration
name                = "mysql-flexible-server-prod-1"
resource_group_name = "rg-mysql-flexible-01"
location            = "canada central"

# ============================================
# Network Configuration
# ============================================

# Delegated Subnet for MySQL
delegated_subnet_id = "/subscriptions/1b48eaaa-febf-4c0d-9d42-5b36ef4d7ac1/resourceGroups/rg-mysql-flexible-01/providers/Microsoft.Network/virtualNetworks/vnet-mysql/subnets/snet-mysql-delegated"

# Private DNS Zone
private_dns_zone_id = "/subscriptions/1b48eaaa-febf-4c0d-9d42-5b36ef4d7ac1/resourceGroups/rg-mysql-flexible-01/providers/Microsoft.Network/privateDnsZones/privatelink.mysql.database.azure.com"

# Public Network Access - Disabled for security
public_network_access = "Disabled"

# ============================================
# Authentication Configuration
# ============================================

# MySQL Administrator Credentials
administrator_login    = "mysqladmin"
administrator_password = "YourSecurePassword123!" # Change this to a strong password

# ============================================
# Customer Managed Key (CMK) Configuration
# ============================================

# Managed Identity for CMK
managed_identities = {
  user_assigned_resource_ids = [
    "/subscriptions/1b48eaaa-febf-4c0d-9d42-5b36ef4d7ac1/resourceGroups/rg-mysql-flexible-01/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-mysql-cmk"

  ]
}

# CMK Configuration
customer_managed_key = {
  key_vault_key_id                  = "https://kv-mysql-1764687805.vault.azure.net/keys/key-mysql-cmk/13517d1320354120a57a43d848c03aed"
  primary_user_assigned_identity_id = "/subscriptions/1b48eaaa-febf-4c0d-9d42-5b36ef4d7ac1/resourceGroups/rg-mysql-flexible-01/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-mysql-cmk"
  # Optional: Uncomment if using geo-redundant backup with separate CMK
  # geo_backup_key_vault_key_id          = "https://kv-mysql-geo.vault.azure.net/keys/key-mysql-cmk-geo/<KEY_VERSION>"
  # geo_backup_user_assigned_identity_id = "/subscriptions/1b48eaaa-febf-4c0d-9d42-5b36ef4d7ac1/resourceGroups/rg-mysql-flexible-geo/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-mysql-cmk-geo"
}

# ============================================
# Private Endpoint Configuration
# ============================================

private_endpoints = {
  primary = {
    name                        = "pe-mysql-primary"
    subnet_resource_id          = "/subscriptions/1b48eaaa-febf-4c0d-9d42-5b36ef4d7ac1/resourceGroups/rg-mysql-flexible-01/providers/Microsoft.Network/virtualNetworks/vnet-mysql/subnets/snet-privateendpoints"
    subresource_name            = "mysqlServer"
    private_dns_zone_group_name = "default"
    private_dns_zone_resource_ids = [
      "/subscriptions/1b48eaaa-febf-4c0d-9d42-5b36ef4d7ac1/resourceGroups/rg-mysql-flexible-01/providers/Microsoft.Network/privateDnsZones/privatelink.mysql.database.azure.com"
    ]
    private_service_connection_name = "psc-mysql-primary"
    network_interface_name          = "nic-mysql-pe-primary"

    # Optional: Tags for private endpoint
    tags = {
      Environment = "Production"
      Purpose     = "MySQL-Private-Access"
    }
  }
}

# Manage private DNS zone groups

# ============================================
# Server Configuration
# ============================================

# MySQL Version
mysql_version = "8.0.21"

# SKU Configuration
sku_name = "GP_Standard_D4ds_v4" # General Purpose, 4 vCores, 16GB RAM

# Availability Zone
#zone = "1"

# ============================================
# High Availability Configuration
# ============================================

# #high_availability = {
#   mode                      = "ZoneRedundant"
#   standby_availability_zone = "1"
# #}

# ============================================
# Storage Configuration
# ============================================

# storage = {
#   auto_grow_enabled  = true
#   io_scaling_enabled = false
#   iops               = 360
#   size_gb            = 20
# }

# ============================================
# Backup Configuration
# ============================================

backup_retention_days        = 14
geo_redundant_backup_enabled = false

# ============================================
# Maintenance Window Configuration
# ============================================

maintenance_window = {
  day_of_week  = "0" # Sunday
  start_hour   = 2   # 2 AM
  start_minute = 0
}

# ============================================
# Database Configuration
# ============================================

databases_name = "app_database-01"
# ============================================
# Server Configuration Parameters
# ============================================

# mysql_configurations = {
#   max_connections = {
#     name  = "max_connections"
#     value = "500"
#   }
#   slow_query_log = {
#     name  = "slow_query_log"
#     value = "ON"
#   }
#   long_query_time = {
#     name  = "long_query_time"
#     value = "2"
#   }
# }

# ============================================
# Firewall Rules (Optional - only if needed)
# ============================================

# Note: With private endpoints and public_network_access = "Disabled",
# firewall rules are typically not needed. Uncomment only if required.

# mysql_firewall_rules = {
#   allow_azure_services = {
#     start_ip_address = "0.0.0.0"
#     end_ip_address   = "0.0.0.0"
#   }
# }

# ============================================
# Azure AD Authentication (Optional)
# ==============0==============================

# Uncomment and configure if using Azure AD authentication
active_directory_administrator = {
   login     = "mysql-admin-group"
   object_id = "f7d6ed3b-9c5d-4a04-9b7b-288538e4a2be"
   tenant_id = "ae5e3109-ff3b-4a4b-8750-bcb7f8ffa486"
 }

# ============================================
# Diagnostic Settings (Optional)
# ============================================

# Uncomment and update workspace_resource_id if you have Log Analytics
# diagnostic_settings = {
#   mysql_diagnostics = {
#     name                           = "diag-mysql-logs"
#     log_groups                     = ["allLogs"]
#     metric_categories              = ["AllMetrics"]
#     log_analytics_destination_type = "Dedicated"
#     workspace_resource_id          = "/subscriptions/1b48eaaa-febf-4c0d-9d42-5b36ef4d7ac1/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/log-analytics-workspace"
#   }
# }

# ============================================
# Resource Lock (Optional)
# ============================================

# lock = {
#   kind = "CanNotDelete"
#   name = "mysql-resource-lock"
# }

# ============================================
# Role Assignments (Optional)
# ============================================

# role_assignments = {
#   db_admin = {
#     role_definition_id_or_name = "Contributor"
#     principal_id               = "<PRINCIPAL_ID>"
#     description                = "Database Administrator Access"
#   }
# }

# ============================================
# Tags
# ============================================

tags = {
  Environment        = "Production"
  Project            = "MySQL-Database"
  ManagedBy          = "Terraform"
  CostCenter         = "IT-Database"
  DataClassification = "Confidential"
  BackupEnabled      = "Yes"
  CMKEnabled         = "Yes"
  Compliance         = "HIPAA"
}

# ============================================
# Telemetry
# ============================================

enable_telemetry = false