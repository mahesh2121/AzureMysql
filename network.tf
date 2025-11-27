# Virtual Network
resource "azurerm_virtual_network" "mysql-vnet" {
  name                = "vnet-${var.mysqlfexiableservername}"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# Subnet for MySQL with delegation
resource "azurerm_subnet" "mysql" {
  name                 = "snet-${var.mysqlfexiableservername}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.mysql-vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "mysql-flex-delegation"

    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

resource "azurerm_subnet" "private_endpoint" {
  name                 = "snet-${var.mysqlfexiableservername}-pe"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.mysql-vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  depends_on = [
    module.mysql_flex.name
  ]

}