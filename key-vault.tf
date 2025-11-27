################################################################################
# Data Sources
################################################################################

data "azurerm_client_config" "current" {}

################################################################################
# Key Vault
################################################################################

resource "azurerm_key_vault" "main" {
  name                          = var.azurerm_key_vault_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "premium"
  public_network_access_enabled = true
  soft_delete_retention_days    = 90  # Changed from 7 to 90 (required for MySQL CMK)
  purge_protection_enabled      = true
  enabled_for_disk_encryption   = true
  rbac_authorization_enabled     = false  # Changed property name

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
  }

  tags = var.tags
}

################################################################################
# Key Vault Access Policies
################################################################################

# Access Policy for Current User/Service Principal
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Backup",
    "Create",
    "Delete",
    "Get",
    "GetRotationPolicy",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "SetRotationPolicy",
    "Update",
    "Rotate"
  ]

  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Set"
  ]

  depends_on = [azurerm_key_vault.main]
}

# Access Policy for MySQL Managed Identity
resource "azurerm_key_vault_access_policy" "mysql_identity" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.mysql.principal_id

  key_permissions = [
    "Get",
    "List",
    "UnwrapKey",
    "WrapKey"
  ]

  depends_on = [
    azurerm_key_vault.main,
    azurerm_user_assigned_identity.mysql
  ]
}

################################################################################
# Role Assignments (Optional - only if using RBAC)
################################################################################

# Uncomment if you want to use RBAC instead of access policies
# Note: Set enable_rbac_authorization = true in Key Vault if using these

# resource "azurerm_role_assignment" "kv_admin_current_user" {
#   scope                = azurerm_key_vault.main.id
#   role_definition_name = "Key Vault Administrator"
#   principal_id         = data.azurerm_client_config.current.object_id
# }

# resource "azurerm_role_assignment" "kv_crypto_user_mysql" {
#   scope                = azurerm_key_vault.main.id
#   role_definition_name = "Key Vault Crypto User"
#   principal_id         = azurerm_user_assigned_identity.mysql.principal_id
# }

################################################################################
# Wait for Access Policies to Propagate
################################################################################

resource "time_sleep" "wait_for_keyvault" {
  create_duration = "60s"

  depends_on = [
    azurerm_key_vault_access_policy.current_user,
    azurerm_key_vault_access_policy.mysql_identity
  ]

  triggers = {
    key_vault_id = azurerm_key_vault.main.id
    user_policy  = azurerm_key_vault_access_policy.current_user.id
    mysql_policy = azurerm_key_vault_access_policy.mysql_identity.id
  }
}

################################################################################
# Key Vault Secret - MySQL Password
################################################################################

resource "azurerm_key_vault_secret" "mysql_admin_password" {
  name         = var.mysql_sescretname
  value        = var.administrator_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_key_vault_access_policy.current_user,
    time_sleep.wait_for_keyvault
  ]

  tags = var.tags
}

################################################################################
# Key Vault Key - Customer Managed Key (CMK)
################################################################################

resource "azurerm_key_vault_key" "mysql_cmk" {
  name         = "mysql-cmk-key-${var.mysqlfexiableservername}"
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }
    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }

  depends_on = [
    azurerm_key_vault_access_policy.current_user,
    time_sleep.wait_for_keyvault
  ]
  lifecycle {
    ignore_changes = [
      # Prevents refresh from failing when permissions aren't set yet
    ]
  }
  tags = var.tags
}

################################################################################
# Data Source to Read Secret (if needed)
################################################################################

data "azurerm_key_vault_secret" "mysql_admin_password_read" {
  name         = azurerm_key_vault_secret.mysql_admin_password.name
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
      azurerm_key_vault_secret.mysql_admin_password
    
  ]
}

