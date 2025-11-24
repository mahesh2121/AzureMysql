resource "azurerm_user_assigned_identity" "uami" {
  name                = "mysql-flex-uami"
  resource_group_name = var.resource_group_name
  location            = var.location
}
