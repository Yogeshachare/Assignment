resource "azurerm_resource_group" "logicGroup" {
  name = "logicGroup"
  location = "eastasia"
}

resource "azurerm_logic_app_workflow" "logicApp" {
  name                = "logicApp"
  location            = azurerm_resource_group.logicGroup.location
  resource_group_name = azurerm_resource_group.logicGroup.name
}

resource "azurerm_logic_app_trigger_http_request" "httpTrigger" {
  name         = "httpTrigger"
  logic_app_id = azurerm_logic_app_workflow.logicApp.id
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
