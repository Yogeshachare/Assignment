resource "azurerm_resource_group" "serviceBusGroup" {
  name = "serviceBusGroup"
  location = "eastasia"
}

resource "azurerm_servicebus_namespace" "serviceBus998" {
  name = "serviceBus998"
  location = azurerm_resource_group.serviceBusGroup.location
  resource_group_name = azurerm_resource_group.serviceBusGroup.name
  sku = "Standard"
}

resource "azurerm_servicebus_topic" "serviceBusTopic" {
  name = "serviceBusTopic"
  namespace_id = azurerm_servicebus_namespace.serviceBus998.id
}

resource "azurerm_servicebus_subscription" "postSubscription" {
  name = "postSubscriptionp"
  topic_id = azurerm_servicebus_topic.serviceBusTopic.id
  max_delivery_count = 5
}

resource "azurerm_servicebus_subscription" "videoSubscription" {
  name = "videoSubscriptionp"
  topic_id = azurerm_servicebus_topic.serviceBusTopic.id
  max_delivery_count = 5
}

resource "azurerm_servicebus_subscription_rule" "postSubFilter" {
  name = "postSubFilter"
  subscription_id = azurerm_servicebus_subscription.postSubscription.id
  filter_type = "CorrelationFilter"

  correlation_filter {
    label = "post"
  }
}

resource "azurerm_servicebus_subscription_rule" "videoSubFilter" {
  name = "videoSubFilter"
  subscription_id = azurerm_servicebus_subscription.videoSubscription.id
  filter_type = "CorrelationFilter"

  correlation_filter {
    label = "video"
  }
}

resource "azurerm_servicebus_queue" "example" {
  name         = "tfex_servicebus_queue"
  namespace_id = azurerm_servicebus_namespace.serviceBus998.id
  requires_duplicate_detection = true
}