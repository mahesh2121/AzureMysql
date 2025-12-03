# ============================================
# Required Variables
# ============================================

variable "name" {
  description = "The name of the MySQL Flexible Server"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where the resource should be deployed"
  type        = string
}

# ============================================
# Network Configuration
# ============================================

variable "delegated_subnet_id" {
  description = "The ID of the virtual network subnet to create the MySQL Flexible Server"
  type        = string
}

variable "private_dns_zone_id" {
  description = "The ID of the private DNS zone to create the MySQL Flexible Server"
  type        = string
  default     = null
}

variable "public_network_access" {
  description = "Whether public network access is allowed for the MySQL Flexible Server"
  type        = string
  default     = "Disabled"
}

# ============================================
# Authentication Configuration
# ============================================

variable "administrator_login" {
  description = "The Administrator login for the MySQL Flexible Server"
  type        = string
  default     = null
}

variable "administrator_password" {
  description = "The Password associated with the administrator_login for the MySQL Flexible Server"
  type        = string
  sensitive   = true
  default     = null
}

variable "active_directory_administrator" {
  description = "Azure AD administrator configuration"
  type = object({
    identity_id = optional(string)
    login       = string
    object_id   = string
    tenant_id   = string
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }))
  })
  default = null
}

# ============================================
# Managed Identity Configuration
# ============================================

variable "managed_identities" {
  description = "Managed identities to be created for the resource"
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default = {}
}

# ============================================
# Customer Managed Key Configuration
# ============================================
variable "entra_admin_object_id" {
  description = "The object ID of the Entra ID administrator group"
  type        = string
  default     = null
}


variable "customer_managed_key" {
  description = "Customer-managed keys to associate with the resource"
  type = object({
    key_vault_key_id                     = string
    geo_backup_key_vault_key_id          = optional(string)
    geo_backup_user_assigned_identity_id = optional(string)
    primary_user_assigned_identity_id    = optional(string)
  })
  default = null
}

# ============================================
# Private Endpoint Configuration
# ============================================

variable "private_endpoints" {
  description = "A map of private endpoints to create on the MySQL Flexible Server"
  type = map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
  default = {}
}

variable "private_endpoints_manage_dns_zone_group" {
  description = "Whether to manage private DNS zone groups with this module"
  type        = bool
  default     = true
}

# ============================================
# Server Configuration
# ============================================

variable "mysql_version" {
  description = "The version of the MySQL Flexible Server to use"
  type        = string
  default     = null
}

variable "sku_name" {
  description = "The SKU Name for the MySQL Flexible Server"
  type        = string
  default     = null
}

variable "zone" {
  description = "Specifies the Availability Zone in which this MySQL Flexible Server should be located"
  type        = string
  default     = null
}

variable "create_mode" {
  description = "The creation mode which can be used to restore or replicate existing servers"
  type        = string
  default     = null
}

variable "source_server_id" {
  description = "The resource ID of the source MySQL Flexible Server to be restored"
  type        = string
  default     = null
}

variable "point_in_time_restore_time_in_utc" {
  description = "The point in time to restore from creation_source_server_id when create_mode is PointInTimeRestore"
  type        = string
  default     = null
}

# ============================================
# High Availability Configuration
# ============================================

variable "high_availability" {
  description = "High availability configuration for the MySQL Flexible Server"
  type = object({
    mode                      = string
    standby_availability_zone = optional(string)
  })
  default = {
    mode                      = "ZoneRedundant"
    standby_availability_zone = null
  }
}

# ============================================
# Storage Configuration
# ============================================

variable "storage" {
  description = "Storage configuration for the MySQL Flexible Server"
  type = object({
    auto_grow_enabled  = optional(bool)
    io_scaling_enabled = optional(bool)
    iops               = optional(number)
    size_gb            = optional(number)
  })
  default = null
}

# ============================================
# Backup Configuration
# ============================================

variable "backup_retention_days" {
  description = "The backup retention days for the MySQL Flexible Server"
  type        = number
  default     = null
}

variable "geo_redundant_backup_enabled" {
  description = "Should geo redundant backup be enabled"
  type        = bool
  default     = true
}

# ============================================
# Maintenance Window Configuration
# ============================================

variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    day_of_week  = optional(string)
    start_hour   = optional(number)
    start_minute = optional(number)
  })
  default = {
    day_of_week = "0"
  }
}

# ============================================
# Database Configuration
# ============================================
#===========================================

variable "databases_name" {
  description = "The name of the database to create on the MySQL Flexible Server"
  type        = string
  default     = null

}

variable "mysql_configurations" {
  description = "Map of MySQL server configuration parameters"
  type = map(object({
    name  = string
    value = string
  }))
  default = {}
}


# ============================================
# Diagnostic Settings
# ============================================

variable "diagnostic_settings" {
  description = "A map of diagnostic settings to create on the MySQL Flexible Server"
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default = {}
}

# ============================================
# Resource Lock
# ============================================

variable "lock" {
  description = "Controls the Resource Lock configuration for this resource"
  type = object({
    kind = string
    name = optional(string, null)
  })
  default = null
}

# ============================================
# Role Assignments
# ============================================

variable "role_assignments" {
  description = "A map of role assignments to create on the MySQL Flexible Server"
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default = {}
}

# ============================================
# Tags
# ============================================

variable "tags" {
  description = "Tags which should be assigned to the MySQL Flexible Server"
  type        = map(string)
  default     = null
}

# ============================================
# Telemetry
# ============================================

variable "enable_telemetry" {
  description = "Controls whether or not telemetry is enabled for the module"
  type        = bool
  default     = true
}