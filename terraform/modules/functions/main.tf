resource "azurerm_service_plan" "functions" {
  name                = "asp-func-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# Function 1: Upload Processor  (Blob trigger -> Service Bus)
# ---------------------------------------------------------------------------

resource "azurerm_linux_function_app" "upload_processor" {
  name                       = "func-upload-${var.project}-${var.environment}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = azurerm_service_plan.functions.id
  storage_account_name       = var.storage_account_name
  storage_uses_managed_identity = true
  virtual_network_subnet_id  = var.subnet_id
  https_only                 = true
  tags                        = var.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version     = "1.2"
    ftps_state              = "Disabled"
    vnet_route_all_enabled  = true

    application_stack {
      node_version = "20"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"               = "node"
    "APPLICATIONINSIGHTS_CONNECTION_STRING"  = var.app_insights_connection_string
    "KEY_VAULT_URI"                          = var.key_vault_uri
    "SERVICEBUS_FQDN"                        = var.servicebus_namespace_fqdn
    "SERVICEBUS_QUEUE_NAME"                  = var.servicebus_queue_name
    "AzureWebJobsStorage__accountName"       = var.storage_account_name
    "WEBSITE_CONTENTOVERVNET"                = "1"
  }
}

# ---------------------------------------------------------------------------
# Function 2: Document Processor  (Service Bus trigger -> Blob + SQL)
# ---------------------------------------------------------------------------

resource "azurerm_linux_function_app" "document_processor" {
  name                       = "func-docproc-${var.project}-${var.environment}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = azurerm_service_plan.functions.id
  storage_account_name       = var.storage_account_name
  storage_uses_managed_identity = true
  virtual_network_subnet_id  = var.subnet_id
  https_only                 = true
  tags                        = var.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version    = "1.2"
    ftps_state             = "Disabled"
    vnet_route_all_enabled = true

    application_stack {
      node_version = "20"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"              = "node"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string
    "KEY_VAULT_URI"                         = var.key_vault_uri
    "SERVICEBUS_FQDN"                       = var.servicebus_namespace_fqdn
    "SERVICEBUS_QUEUE_NAME"                 = var.servicebus_queue_name
    "SQL_CONNECTION_STRING"                 = "@Microsoft.KeyVault(SecretUri=${var.key_vault_uri}secrets/${var.sql_connection_secret_name}/)"
    "STORAGE_BLOB_ENDPOINT"                 = "@Microsoft.KeyVault(SecretUri=${var.key_vault_uri}secrets/${var.blob_endpoint_secret_name}/)"
    "AzureWebJobsStorage__accountName"      = var.storage_account_name
    "WEBSITE_CONTENTOVERVNET"               = "1"
  }
}

resource "azurerm_monitor_diagnostic_setting" "upload_processor" {
  name                       = "diag-func-upload-${var.environment}"
  target_resource_id         = azurerm_linux_function_app.upload_processor.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "FunctionAppLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "document_processor" {
  name                       = "diag-func-docproc-${var.environment}"
  target_resource_id         = azurerm_linux_function_app.document_processor.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "FunctionAppLogs"
  }

  metric {
    category = "AllMetrics"
  }
}
