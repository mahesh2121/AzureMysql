module "mysql_flex" {
  source  = "Azure/avm-res-dbformysql-flexibleserver/azurerm"
  version = "0.1.5"

  name                = "mysql-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  administrator_login    = "dbadmin"
  administrator_password = random_password.mysql_admin.result

  delegated_subnet_id = azurerm_subnet.mysql_subnet.id
  private_dns_zone_id = azurerm_private_dns_zone.mysql_private_dns.id

  sku_name = "Standard_D4ads_v5"

  storage = {
    size_gb = 32
  }

  high_availability = {
    mode = "ZoneRedundant"
  }

  managed_identities = {
    system_assigned = false
    user_assigned_resource_ids = [
      azurerm_user_assigned_identity.uami.id
    ]
  }

  tags = var.tags
}
