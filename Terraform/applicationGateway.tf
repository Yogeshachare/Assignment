resource "azurerm_resource_group" "applicationGatewayGroup" {
  name = "applicationGatewayGroup"
  location = "eastasia"
}

resource "azurerm_virtual_network" "vnet" {
  name = "vnet"
  resource_group_name = azurerm_resource_group.applicationGatewayGroup.name
  location = azurerm_resource_group.applicationGatewayGroup.location
  address_space = [ "10.0.0.0/16" ]
  depends_on = [
    azurerm_resource_group.applicationGatewayGroup
  ]
}

resource "azurerm_subnet" "SubnetA" {
  name = "SubnetA"
  resource_group_name = azurerm_resource_group.applicationGatewayGroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [ "10.0.0.0/24" ]
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_subnet" "SubnetB" {
  name                 = "SubnetB"
  resource_group_name  = azurerm_resource_group.applicationGatewayGroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_network_interface" "app_interface1" {
  name                = "app-interface1"
  location            = azurerm_resource_group.applicationGatewayGroup.location
  resource_group_name = azurerm_resource_group.applicationGatewayGroup.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"    
  }

  depends_on = [
    azurerm_virtual_network.vnet,
    azurerm_subnet.SubnetA
  ]
}

resource "azurerm_network_interface" "app_interface2" {
  name                = "app-interface2"
  location = azurerm_resource_group.applicationGatewayGroup.location
  resource_group_name = azurerm_resource_group.applicationGatewayGroup.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"    
  }

  depends_on = [
    azurerm_virtual_network.vnet,
    azurerm_subnet.SubnetA
  ]
}

resource "azurerm_windows_virtual_machine" "vm01" {
  name = "vm01"
  location = azurerm_resource_group.applicationGatewayGroup.location
  resource_group_name = azurerm_resource_group.applicationGatewayGroup.name
  size = "Standard_D2s_v3"
  admin_username = "yogesh"
  admin_password = "Azure@123"
  network_interface_ids = [
    azurerm_network_interface.app_interface1.id,
  ]

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-datacenter-gensecond"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.app_interface1
  ]
}

resource "azurerm_windows_virtual_machine" "vm02" {
  name = "vm02"
  location = azurerm_resource_group.applicationGatewayGroup.location
  resource_group_name = azurerm_resource_group.applicationGatewayGroup.name
  size = "Standard_D2s_v3"
  admin_username = "yogesh"
  admin_password = "Azure@123"
  network_interface_ids = [ 
    azurerm_network_interface.app_interface2.id, 
    ]

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer = "WindowsServer"
    sku = "2016-datacenter-gensecond"
    version = "latest"
  }

  depends_on = [
    azurerm_network_interface.app_interface2
  ]
}

resource "azurerm_network_security_group" "appnsg" {
  name = "appnsg"
  location = azurerm_resource_group.applicationGatewayGroup.location
  resource_group_name = azurerm_resource_group.applicationGatewayGroup.name

  security_rule {
    name =  "Allow_HTTP"
    priority = "200"
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "80"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id = azurerm_subnet.SubnetA.id
  network_security_group_id = azurerm_network_security_group.appnsg.id
  depends_on = [
    azurerm_network_security_group.appnsg
  ]
}

resource "azurerm_public_ip" "gatewayIp" {
  name = "gatewayIp"
  resource_group_name = azurerm_resource_group.applicationGatewayGroup.name
  location = azurerm_resource_group.applicationGatewayGroup.location
  allocation_method = "Dynamic"
}

resource "azurerm_application_gateway" "app_gateway" {
  name = "app-gateway"
  resource_group_name = azurerm_resource_group.applicationGatewayGroup.name
  location = azurerm_resource_group.applicationGatewayGroup.location

  sku {
    name     = "Standard_Medium"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name = "gateway-ip-config"
    subnet_id = azurerm_subnet.SubnetB.id
  }
  
  frontend_port {
    name = "front-end-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "front-end-ip-config"
    public_ip_address_id = azurerm_public_ip.gatewayIp.id    
  }

  backend_address_pool {
    name = "videopool"
    ip_addresses = [
      "${azurerm_network_interface.app_interface1.private_ip_address}"
    ]
  }

  backend_address_pool {
    name = "imagepool"
    ip_addresses = [
      "${azurerm_network_interface.app_interface2.private_ip_address}"
    ]
  }

  backend_http_settings {
    name                  = "HTTPSetting"
    cookie_based_affinity = "Disabled"
    path                  = ""
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }


 http_listener {
    name                           = "gateway-listener"
    frontend_ip_configuration_name = "front-end-ip-config"
    frontend_port_name             = "front-end-port"
    protocol                       = "Http"
  }

// This is used for implementing the URL routing rules
 request_routing_rule {
    name               = "RoutingRuleA"
    rule_type          = "PathBasedRouting"
    url_path_map_name  = "RoutingPath"
    http_listener_name = "gateway-listener"
  }

  url_path_map {
    name                               = "RoutingPath"    
    default_backend_address_pool_name   = "videopool"
    default_backend_http_settings_name  = "HTTPSetting"

     path_rule {
      name                          = "VideoRoutingRule"
      backend_address_pool_name     = "videopool"
      backend_http_settings_name    = "HTTPSetting"
      paths = [
        "/videos/*",
      ]
    }

    path_rule {
      name                          = "ImageRoutingRule"
      backend_address_pool_name     = "imagepool"
      backend_http_settings_name    = "HTTPSetting"
      paths = [
        "/images/*",
      ]
    }
  }
}