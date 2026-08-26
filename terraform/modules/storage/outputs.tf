output "storage_account_id" {
  value = azurerm_storage_account.this.id
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.this.primary_blob_endpoint
}

output "container_names" {
  value = {
    incoming  = azurerm_storage_container.incoming.name
    processed = azurerm_storage_container.processed.name
    rejected  = azurerm_storage_container.rejected.name
  }
}
