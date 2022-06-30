#Resource Group
resource "azurerm_resource_group" "rg01" {
  name     = "vmScaleSetRg"
  location = "eastasia"
}

#Virtual Network
resource "azurerm_virtual_network" "vnet01" {
  name                = "vnet01"
  resource_group_name = azurerm_resource_group.rg01.name
  location            = azurerm_resource_group.rg01.location
  address_space       = ["10.0.0.0/16"]
}

#Subnet
resource "azurerm_subnet" "subnet01" {
  name                 = "subnet01"
  resource_group_name  = azurerm_resource_group.rg01.name
  virtual_network_name = azurerm_virtual_network.vnet01.name
  address_prefixes     = ["10.0.0.0/24"]
}

#public Ip
resource "azurerm_public_ip" "loadIp" {
  name = "loadIp"
  location = azurerm_resource_group.rg01.location
  resource_group_name = azurerm_resource_group.rg01.name
  allocation_method = "Static"
  sku = "Standard"
}

#load Balancer
resource "azurerm_lb" "appLb" {
  name = "appLb"
  location = azurerm_resource_group.rg01.location
  resource_group_name = azurerm_resource_group.rg01.name
  sku = "Standard"
  sku_tier = "Regional"
  frontend_ip_configuration {
    name = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.loadIp.id
  }

  depends_on = [
    azurerm_public_ip.loadIp
  ]
}

#backend Pool
resource "azurerm_lb_backend_address_pool" "scaleSetPool" {
  loadbalancer_id = azurerm_lb.appLb.id
  name = "scaleSetPool"
  depends_on = [
    azurerm_lb.appLb
  ]
}

resource "azurerm_lb_probe" "ProbeA" {
  loadbalancer_id = azurerm_lb.appLb.id
  name = "ProbeA"
  port = 80
  protocol = "Tcp"
  depends_on = [
    azurerm_lb.appLb
  ]
}

#loadBalancer Rule
resource "azurerm_lb_rule" "Rule01" {
  loadbalancer_id = azurerm_lb.appLb.id
  name = "Rule01"
  protocol = "Tcp"
  frontend_port = 80
  backend_port = 80
  frontend_ip_configuration_name = "frontend-ip"
  probe_id = azurerm_lb_probe.ProbeA.id
  backend_address_pool_ids = [ azurerm_lb_backend_address_pool.scaleSetPool.id ]
}

#Scale Set
resource "azurerm_windows_virtual_machine_scale_set" "scaleSet" {
  name                = "scaleSet"
  resource_group_name = azurerm_resource_group.rg01.name
  location            = azurerm_resource_group.rg01.location
  sku                 = "Standard_D2s_v3"
  instances           = 2
  admin_password      = "Azure@123"
  admin_username      = "yogesh"

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "scaleset-interface"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.subnet01.id
      load_balancer_backend_address_pool_ids = [ azurerm_lb_backend_address_pool.scaleSetPool.id ]
    }
  }
  depends_on = [
    azurerm_virtual_network.vnet01
  ]
}

# Storage
resource "azurerm_storage_account" "appstorage998" {
  name = "appstorage998"
  resource_group_name = azurerm_resource_group.rg01.name
  location = azurerm_resource_group.rg01.location
  account_tier = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = "appstorage998"
  container_access_type = "blob"
  depends_on=[
    azurerm_storage_account.appstorage998
    ]
}

resource "azurerm_storage_blob" "IIS_Config" {
  name                   = "IIS_Config.ps1"
  storage_account_name   = "appstorage998"
  storage_container_name = "data"
  type                   = "Block"
  source                 = "IIS_Config.ps1"
   depends_on=[azurerm_storage_container.data]
}

# Scale Set extension
resource "azurerm_virtual_machine_scale_set_extension" "scaleSet-extensions" {
  name                         = "scaleSet-extension"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.scaleSet.id
  publisher                    = "Microsoft.Compute"
  type                         = "CustomScriptExtension"
  type_handler_version         = "1.9"
  depends_on = [
    azurerm_storage_blob.IIS_Config
  ]
  settings = <<SETTINGS
  {
    "fileUris": ["https://${azurerm_storage_account.appstorage998.name}.blob.core.windows.net/data/IIS_Config.ps1"],
      "commandToExecute":"powershell -ExecutionPolicy Unrestricted -file IIS_Config.ps1"
  }
  SETTINGS
}

# Network Security Group
resource "azurerm_network_security_group" "nsg01" {
  name = "nsg01"
  location = azurerm_resource_group.rg01.location
  resource_group_name = azurerm_resource_group.rg01.name

  security_rule {
    name = "Allow_HTTP"
    priority = 200
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "80"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_asso" {
  subnet_id = azurerm_subnet.subnet01.id
  network_security_group_id = azurerm_network_security_group.nsg01.id
  depends_on = [
    azurerm_network_security_group.nsg01
  ]
}
