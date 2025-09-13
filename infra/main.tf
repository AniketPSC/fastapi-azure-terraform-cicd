# Fetch current tenant/subscription info
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
}

# Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"

  # For learning/demo purpose we enable admin credentials (username/password).
  # In production prefer service principal/OIDC or managed identities.
  admin_enabled = true
}

# App Service Plan (Linux)
resource "azurerm_app_service_plan" "asp" {
  name                = local.plan_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Create Linux plan suitable for Linux containers
  kind     = "Linux"
  reserved = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

# App Service (Web App) - configured for container (placeholder image)
resource "azurerm_app_service" "app" {
  name                = local.app_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.asp.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    # placeholder Docker image so the service is created as a container host.
    # The CI job (GitHub Actions) will update the container later with the built image.
    linux_fx_version = "DOCKER|mcr.microsoft.com/azuredocs/azure-vote-front:v1"
    always_on        = true
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITES_PORT"                       = "8000"
    "DOCKER_REGISTRY_SERVER_URL"          = "https://${azurerm_container_registry.acr.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME"     = azurerm_container_registry.acr.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = azurerm_container_registry.acr.admin_password
  }
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                = local.key_vault_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # NOTE: if you previously had trouble with soft_delete, omit this property.
  # soft_delete_enabled = true   # (omit or enable depending on your subscription / provider)
}

# A sample secret in Key Vault
resource "azurerm_key_vault_secret" "sample" {
  name         = "sample-secret"
  value        = "very-secret-value"
  key_vault_id = azurerm_key_vault.kv.id
}

# Grant the Web App's system-assigned identity permission to READ secrets
resource "azurerm_key_vault_access_policy" "webapp_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_app_service.app.identity[0].principal_id

  # IMPORTANT: use capitalized permission names (Get, List, Set, Delete, ...)
  secret_permissions = [
    "Get",
    "List"
  ]
}

# Allow the current Azure CLI user to manage Key Vault
resource "azurerm_key_vault_access_policy" "me" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete"
  ]
}

