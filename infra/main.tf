# Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = var.location
}

# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
}

# App Service Plan
resource "azurerm_app_service_plan" "main" {
  name                = local.plan_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku {
    tier = "Basic"
    size = "B1"
  }
}

# App Service (Web App)
resource "azurerm_app_service" "app" {
  name                = local.app_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  app_service_plan_id = azurerm_app_service_plan.main.id

  site_config {
    always_on = true
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DOCKER_REGISTRY_SERVER_URL"          = azurerm_container_registry.acr.login_server
    "DOCKER_REGISTRY_SERVER_USERNAME"     = azurerm_container_registry.acr.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = azurerm_container_registry.acr.admin_password
    "WEBSITES_PORT"                       = "8000"
  }
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = local.key_vault_name
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"


  purge_protection_enabled    = false
}

# Get client details
data "azurerm_client_config" "current" {}
