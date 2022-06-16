terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}
provider "azurerm" {
    features {}
    subscription_id = "2fc41cd7-4e3c-4339-9a34-108ab169f022"
    tenant_id = "64593750-afa4-45d3-8ebf-145d1d91a713"
}

#resource group
resource "azurerm_resource_group" "rg01" {
  name = "demoLogicApp"
  location = "eastus"
}

# Logic App
resource "azurerm_logic_app_workflow" "logicApp01" {
  name = "logicApp01"
  location = azurerm_resource_group.rg01.location
  resource_group_name = azurerm_resource_group.rg01.name
}

resource "azurerm_logic_app_trigger_http_request" "example" {
  name         = "some-http-trigger"
  logic_app_id = azurerm_logic_app_workflow.logicApp01.id
  method = "GET"

  schema = <<SCHEMA
{
    "type": "object",
    "properties": {
        "hello": {
            "type": "string"
        }
    }
}
SCHEMA

}