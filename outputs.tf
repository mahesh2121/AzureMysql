output "mysql_fqdn" {
  value = module.mysql_flex.resource_id
}

output "mysql_admin_password_secret" {
  value = azurerm_key_vault_secret.mysql_password.id
}
