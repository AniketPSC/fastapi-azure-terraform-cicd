output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "app_default_hostname" {
  value = azurerm_app_service.app.default_site_hostname
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}
