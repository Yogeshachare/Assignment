resource "azurerm_resource_group" "sqlGroup" {
  name = "sqlGroup"
  location = "eastasia"
}

resource "azurerm_sql_server" "appserver998" {
  name = "appserver998"
  resource_group_name = azurerm_resource_group.sqlGroup.name
  location = azurerm_resource_group.sqlGroup.location
  version = "12.0"
  administrator_login = "yogesh"
  administrator_login_password = "Azure@123"
}

resource "azurerm_sql_database" "sqlDB" {
  name = "sqlDB"
  resource_group_name = azurerm_resource_group.sqlGroup.name
  location = azurerm_resource_group.sqlGroup.location
  server_name = azurerm_sql_server.appserver998.name
  depends_on = [
    azurerm_sql_server.appserver998
  ]
}

resource "azurerm_sql_firewall_rule" "sqlfirewallRule" {
  name = "sqlfirewallRule"
  resource_group_name = azurerm_resource_group.sqlGroup.name
  server_name = azurerm_sql_server.appserver998.name
  start_ip_address = "192.168.31.179"
  end_ip_address = "192.168.31.179"
}