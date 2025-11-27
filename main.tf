
# MySQL Flexible Server Module
module "mysql_flex" {
  source  = "Azure/avm-res-dbformysql-flexibleserver/azurerm"
  version = "0.1.5"

  name                   = var.mysqlfexiableservername
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = "dbadmin"
  administrator_password = data.azurerm_key_vault_secret.mysql_admin_password_read.value

  mysql_version = var.mysql_version
  sku_name      = var.sku_name

  # Network configuration
  delegated_subnet_id = azurerm_subnet.mysql.id
  private_dns_zone_id = azurerm_private_dns_zone.mysql.id

  # Storage configuration
  storage = {
    size_gb = 20
    iops    = 360

  }

  # Backup configuration
  backup_retention_days        = var.environment == "prod" ? 7 : 1
  geo_redundant_backup_enabled = var.environment == "prod" ? true : false
  # High Availability
  high_availability = {
    mode                      = "SameZone"
    standby_availability_zone = 1
  }

  # Managed Identity
  managed_identities = {
    system_assigned = false
    user_assigned_resource_ids = [
      azurerm_user_assigned_identity.mysql.id
    ]
  }

  customer_managed_key = {
    enabled                           = true
    key_vault_key_id                  = azurerm_key_vault_key.mysql_cmk.id
    primary_user_assigned_identity_id = azurerm_user_assigned_identity.mysql.id
  }


  # Maintenance window (Sunday at midnight)
  maintenance_window = {
    day_of_week  = 0
    start_hour   = 0
    start_minute = 0
  }

  # Databases to create
  databases = {
    app_db = {
      name      = var.database_name
      charset   = "utf8mb3"
      collation = "utf8mb3_general_ci"
    }
  }

  tags = var.tags

  depends_on = [

    azurerm_private_dns_zone_virtual_network_link.mysql


  ]
}



