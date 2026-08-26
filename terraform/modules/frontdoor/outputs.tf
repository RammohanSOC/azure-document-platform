output "endpoint_hostname" {
  value = azurerm_cdn_frontdoor_endpoint.this.host_name
}

output "front_door_id" {
  description = "Resource GUID used for the X-Azure-FDID origin-restriction header"
  value       = azurerm_cdn_frontdoor_profile.this.resource_guid
}

output "profile_resource_id" {
  description = "Full ARM resource ID of the Front Door profile, for alert scopes / RBAC"
  value       = azurerm_cdn_frontdoor_profile.this.id
}

output "waf_policy_id" {
  value = azurerm_cdn_frontdoor_firewall_policy.this.id
}
