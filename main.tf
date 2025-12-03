terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0, < 4.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.11.1, < 2.0.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# MySQL Flexible Server Module
module "mysql_flexible_server" {
  source  = "Azure/avm-res-dbformysql-flexibleserver/azurerm"
  version = "0.1.5" # Specify version in production

  # Required variables
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  # Network configuration
  delegated_subnet_id   = var.delegated_subnet_id
  private_dns_zone_id   = var.private_dns_zone_id
  public_network_access = var.public_network_access

  # Authentication
  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password

  # Managed Identity for CMK
  managed_identities = var.managed_identities

  # Customer Managed Key
  customer_managed_key = var.customer_managed_key

  # Private Endpoints
  private_endpoints                       = var.private_endpoints
  private_endpoints_manage_dns_zone_group = var.private_endpoints_manage_dns_zone_group

  # Server configuration
  mysql_version = var.mysql_version
  sku_name      = var.sku_name
  zone          = var.zone

  # High Availability
  #high_availability = var.high_availability

  # Storage
  storage = var.storage

  # Backup
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  # Maintenance Window
  maintenance_window = var.maintenance_window

  # Databases
  databases = {
    my_database = {
      charset   = "utf8"
      collation = "utf8_unicode_ci"
      name      = var.databases_name
    }
  }
  
  # Server configurations
  #mysql_configurations = var.mysql_configurations

  # Optional: Firewall rules
  #mysql_firewall_rules = var.mysql_firewall_rules

  # Optional: Azure AD Authentication
  active_directory_administrator = var.active_directory_administrator

  # Diagnostic settings
  diagnostic_settings = var.diagnostic_settings

  # Resource lock
  # lock = var.lock

  # Role assignments
  role_assignments = var.role_assignments

  # Tags
  tags = var.tags

  # Telemetry
  enable_telemetry = var.enable_telemetry
}

