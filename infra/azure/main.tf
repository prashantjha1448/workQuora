provider "azurerm" {
  features {}
}

variable "location" {
  type    = string
  default = "East US"
}

resource "azurerm_resource_group" "workquora_rg" {
  name     = "workquora-resources"
  location = var.location
}

resource "azurerm_virtual_network" "workquora_vnet" {
  name                = "workquora-vnet"
  resource_group_name = azurerm_resource_group.workquora_rg.name
  location            = azurerm_resource_group.workquora_rg.location
  address_space       = ["10.0.0.0/16"]
}

output "resource_group_name" {
  value = azurerm_resource_group.workquora_rg.name
}
