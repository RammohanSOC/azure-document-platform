output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "subnet_appservice_id" {
  value = azurerm_subnet.appservice.id
}

output "subnet_functions_id" {
  value = azurerm_subnet.functions.id
}

output "subnet_private_endpoints_id" {
  value = azurerm_subnet.private_endpoints.id
}

output "private_dns_zone_ids" {
  value = { for k, v in azurerm_private_dns_zone.this : k => v.id }
}

output "private_dns_zone_names" {
  value = { for k, v in azurerm_private_dns_zone.this : k => v.name }
}

output "firewall_private_ip" {
  value = var.enable_firewall ? azurerm_firewall.this[0].ip_configuration[0].private_ip_address : null
}
