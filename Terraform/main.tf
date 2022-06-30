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

