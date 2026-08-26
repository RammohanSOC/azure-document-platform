output "upload_processor_id" {
  value = azurerm_linux_function_app.upload_processor.id
}

output "upload_processor_principal_id" {
  value = azurerm_linux_function_app.upload_processor.identity[0].principal_id
}

output "document_processor_id" {
  value = azurerm_linux_function_app.document_processor.id
}

output "document_processor_principal_id" {
  value = azurerm_linux_function_app.document_processor.identity[0].principal_id
}

output "function_principal_ids" {
  value = [
    azurerm_linux_function_app.upload_processor.identity[0].principal_id,
    azurerm_linux_function_app.document_processor.identity[0].principal_id,
  ]
}
