data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                       = "kv-mysql-flex-${var.environment}"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 30

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions    = ["Get", "Create", "List", "Update", "Delete", "Recover", "WrapKey", "UnwrapKey"]
    secret_permissions = ["Set", "Get", "List"]
  }
}

resource "random_password" "mysql_admin" {
  length  = 16
  special = true
}

resource "azurerm_key_vault_secret" "mysql_password" {
  name         = "mysql-admin-password"
  value        = random_password.mysql_admin.result
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_key" "cmk" {
  name         = "mysql-cmk"
  key_vault_id = azurerm_key_vault.kv.id

  key_type = "RSA"
  key_size = 2048

  # REQUIRED IN AZURERM 4.x
  key_opts = [
    "encrypt",
    "decrypt",
    "sign",
    "verify",
    "wrapKey",
    "unwrapKey"
  ]

}


resource "azurerm_key_vault_access_policy" "uami_key" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.uami.principal_id

  key_permissions = ["Get", "WrapKey", "UnwrapKey"]
}
