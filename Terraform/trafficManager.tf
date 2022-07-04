resource "azurerm_resource_group" "trafficManagerGroup" {
  name = "trafficManagerGroup"
  location = "centralus"
}

# primary App service plan
resource "azurerm_app_service_plan" "primaryPlan" {
  name = "primaryPlan"
  location = azurerm_resource_group.trafficManagerGroup.location
  resource_group_name = azurerm_resource_group.trafficManagerGroup.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

# primary App
resource "azurerm_app_service" "primaryApp" {
    name = "primaryApp998"
    location = azurerm_resource_group.trafficManagerGroup.location
    resource_group_name = azurerm_resource_group.trafficManagerGroup.name
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

# secondary App service plan
resource "azurerm_app_service_plan" "secondaryPlan" {
  name = "secondaryPlan"
  location = "eastasia"
  resource_group_name = azurerm_resource_group.trafficManagerGroup.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

# Secondary App
resource "azurerm_app_service" "secondaryApp" {
  name = "secondaryPaln998"
  location = "eastasia"
  resource_group_name = azurerm_resource_group.trafficManagerGroup.name
  app_service_plan_id = azurerm_app_service_plan.secondaryPlan.id
  site_config {
    dotnet_framework_version = "v6.0"
  }
  source_control {
    repo_url = "https://github.com/Yogeshachare/secondaryApp.git"
    branch = "master"
    manual_integration = true
    use_mercurial = false
  }
}

# traffic Profile 
resource "azurerm_traffic_manager_profile" "trafficProfile" {
  name = "trafficProfile998"
  resource_group_name = azurerm_resource_group.trafficManagerGroup.name
  traffic_routing_method = "Priority"
  dns_config {
    relative_name = "trafficProfile998"
    ttl = 100
  }
  monitor_config {
    protocol = "HTTPS"
    port = 443
    path = "/"
    interval_in_seconds = 30
    timeout_in_seconds = 10
    tolerated_number_of_failures = 2
  }
}

# traffic manager primary end Point
resource "azurerm_traffic_manager_azure_endpoint" "primaryEndPoint" {
  name = "primaryEndPoint"
  profile_id = azurerm_traffic_manager_profile.trafficProfile.id
  priority = 1
  weight = 100
  target_resource_id = azurerm_app_service.primaryApp.id
}

# traffic manager secondary end Point
resource "azurerm_traffic_manager_azure_endpoint" "secondaryEndPoint" {
 name = "secondaryEndPoint"
 profile_id = azurerm_traffic_manager_profile.trafficProfile.id
 priority = 2 
 weight = 100
 target_resource_id = azurerm_app_service.secondaryApp.id  
}