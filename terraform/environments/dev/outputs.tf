output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "app_service_default_hostname" {
  value = module.app_service.default_hostname
}

output "front_door_endpoint_hostname" {
  value = module.frontdoor.endpoint_hostname
}

output "front_door_id" {
  description = "Pass this back in as -var=\"front_door_id=<value>\" on the second apply to lock App Service origin access to only this Front Door instance."
  value       = module.frontdoor.front_door_id
}

output "sql_server_fqdn" {
  value = module.sql.sql_server_fqdn
}

output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "servicebus_namespace_fqdn" {
  value = module.servicebus.namespace_fqdn
}

output "log_analytics_workspace_id" {
  value = module.monitoring.log_analytics_workspace_id
}
