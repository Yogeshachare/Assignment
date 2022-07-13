resource "azurerm_resource_group" "webAppGroup" {
  name = "webAppGroup"
  location = "eastasia"
}

resource "azurerm_app_service_plan" "primaryPlan" {
  name = "primaryPlan"
  location = azurerm_resource_group.webAppGroup.location
  resource_group_name = azurerm_resource_group.webAppGroup.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

# primary App
resource "azurerm_app_service" "primaryApp" {
    name = "primaryApp998"
    location = azurerm_resource_group.webAppGroup.location
    resource_group_name = azurerm_resource_group.webAppGroup.name
    app_service_plan_id = azurerm_app_service_plan.primaryPlan.id
    site_config {
      dotnet_framework_version = "v6.0"
    }
    source_control {
      repo_url = "https://github.com/Yogeshachare/primaryApp.git"
      branch = "master"
      manual_integration = true
      use_mercurial = false
    }
}