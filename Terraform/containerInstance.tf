resource "azurerm_resource_group" "containerResourcGroup" {
  name = "containerResourcGroup"
  location = "eastasia"
}

resource "azurerm_container_group" "containerGroup" {
  name = "containerGroup"
  location = azurerm_resource_group.containerResourcGroup.location
  resource_group_name = azurerm_resource_group.containerResourcGroup.name
  ip_address_type     = "Public"
  dns_name_label      = "aci-label"
  os_type             = "Linux"

  container {
    name   = "hello-world"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }
}
