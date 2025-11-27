variable "location" {
  description = "The location where resources will be created."
  type        = string
  default     = "eastus"
}

variable "mysqlfexiableservername" {
  description = "The name of the MySQL Flexible Server."
  type        = string
  default     = "mysql-flex-server-001"

}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the resources."
  type        = string
  default     = "rg-maheshgaikwad-terraform-test-nllz"
}

variable "environment" {
  description = "The environment for the deployment."
  type        = string
  default     = "prod"

}

variable "sku_name" {
  description = "The SKU name for the MySQL Flexible Server."
  type        = string
  default     = "GP_Standard_D2ds_v4"

}

variable "mysql_version" {
  description = "The version of MySQL to use."
  type        = string
  default     = "8.0.21"

}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default = {
    environment = "prod"
    managedBy   = "terraform"
    owner       = "platform-team"
    project     = "mysql-cmk"
  }

}

variable "database_name" {
  description = "The name of the MySQL database to create."
  type        = string
  default     = "mydatabase"

}

variable "mysql_sescretname" {
  description = "The name of the secret in Azure Key Vault for MySQL admin password."
  type        = string
  default     = "mysql-admin-password"

}


variable "administrator_password" {
  description = "The password for the MySQL Flexible Server."
  type        = string
  sensitive   = true

}

# variable "delegated_subnet_id" {
#   description = "The ID of the delegated subnet for MySQL Flexible Server."
#   type        = string


# }

variable "public_ip" {
  description = "value of your public ip address"
  type        = string
  default     = "106.215.178.238"

}

variable "azurerm_key_vault_name" {
  description = "The name of the Azure Key Vault."
  type        = string


}
variable "loggroupname" {
  description = "The name of the Log Analytics workspace."
  type        = string

}