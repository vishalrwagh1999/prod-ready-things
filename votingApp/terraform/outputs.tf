output "acr_id" {
  description = "Full resource ID of the ACR"
  value       = azurerm_container_registry.acr.id
}

output "acr_login_server" {
  description = "Login server FQDN — use as registry in docker login / Helm / k8s imagePullSecrets"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_name" {
  description = "ACR name"
  value       = azurerm_container_registry.acr.name
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.acr_rg.name
}

output "acr_admin_username" {
  description = "Admin username (only populated when admin_enabled = true)"
  value       = "admin_disabled"
  sensitive   = true
}

output "acr_admin_password" {
  description = "Admin password (only populated when admin_enabled = true)"
  value       = "admin_disabled"
  sensitive   = true
}
