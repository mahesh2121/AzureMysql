resource "azurerm_user_assigned_identity" "mysql" {
  name                = "mi-mysql-${var.mysqlfexiableservername}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}