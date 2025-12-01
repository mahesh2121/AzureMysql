terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id = "1b48eaaa-febf-4c0d-9d42-5b36ef4d7ac1"
}

data "azurerm_user_assigned_identity" "mysql_identity" {
  name                = "mysql-cmk-identity"
  resource_group_name = "rg-maheshgaikwad-terraform-test-nllz"
}

module "mysql_flex_server" {
  source  = "Azure/avm-res-dbformysql-flexibleserver/azurerm"
  version = "0.1.5"
  
  name                = "flexmysqldb008"
  resource_group_name = "rg-maheshgaikwad-terraform-test-nllz"
  location            = "canada central"
  
  administrator_login    = "mysqladmin"
  administrator_password = "P@ssw0rd1234!VeryStrong#2024"
  
  sku_name = "GP_Standard_D2ds_v4"
  zone     = "1"
  
  storage = {
    size_gb           = 20
    iops              = 360
    auto_grow_enabled = true
  }
  
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  
  customer_managed_key = {
    key_vault_key_id          = "https://kvmysqlcmk68132.vault.azure.net/keys/mysql-disk-key/4ff7fffbbdbe441fbc0bfd3d72765388"
    primary_user_assigned_identity_id = data.azurerm_user_assigned_identity.mysql_identity.id
  }
  
  managed_identities = {
    user_assigned_resource_ids = [
      data.azurerm_user_assigned_identity.mysql_identity.id
    ]
  }
   high_availability = {
    mode                      = "SameZone"
    standby_availability_zone = 1
   }
  
  role_assignments = {
    user_contributor = {
      role_definition_id_or_name = "Contributor"
      principal_id               = "12f49167-fb9e-491a-82ab-b6371c23d9ac"
      principal_type             = "User"
      description                = "MySQL Server Contributor"
    }
  }
  
  tags = {
    platform    = "MySQL"
    environment = "prod"
    owner       = "chanchalgaikwad25@gmail.com"
    encryption  = "CMK"
    managed_by  = "Terraform"
  }
}

