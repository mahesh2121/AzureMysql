resource "azapi_update_resource" "mysql_cmk" {
  type        = "Microsoft.DBforMySQL/flexibleServers@2023-06-01"
  resource_id = module.mysql_flex.resource_id

  body = jsonencode({
    properties = {
      dataEncryption = {
        type       = "AzureKeyVault"
        identityId = azurerm_user_assigned_identity.uami.id
        keyURI     = azurerm_key_vault_key.cmk.id
      }
    }
  })

  depends_on = [
    module.mysql_flex,
    azurerm_key_vault_key.cmk,
    azurerm_key_vault_access_policy.uami_key
  ]
}
