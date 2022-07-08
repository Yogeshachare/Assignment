resource "azurerm_resource_group" "functionAppGroup" {
  name = "functionAppGroup"
  location = "eastAsia"
}

resource "azurerm_storage_account" "funStorage" {
  name = "funstorage998"
  resource_group_name = azurerm_resource_group.functionAppGroup.name
  location = azurerm_resource_group.functionAppGroup.location
  account_tier = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "appPlan" {
  name = "appPlan"
  location = azurerm_resource_group.functionAppGroup.location
  resource_group_name = azurerm_resource_group.functionAppGroup.name
  kind = "FunctionApp"
  reserved = true
  
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "functionApp" {
  name = "functionApp998"
  location = azurerm_resource_group.functionAppGroup.location
  resource_group_name = azurerm_resource_group.functionAppGroup.name
  app_service_plan_id = azurerm_app_service_plan.appPlan.id
  storage_account_name = azurerm_storage_account.funStorage.name
  storage_account_access_key = azurerm_storage_account.funStorage.primary_access_key
  https_only = true
  version = "~4"
  os_type = "linux"
  site_config {
    linux_fx_version = "Python|3.8"
    ftps_state = "Disabled"
  }
  identity {
    type = "SystemAssigned"
  }
}