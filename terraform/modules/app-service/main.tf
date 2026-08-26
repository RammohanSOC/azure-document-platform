resource "azurerm_service_plan" "this" {
  name                = "asp-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "this" {
  name                = "app-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true
  tags                = var.tags

  virtual_network_subnet_id = var.subnet_id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version = "1.2"
    ftps_state           = "Disabled"
    vnet_route_all_enabled = true
    health_check_path      = "/status"

    application_stack {
      node_version = "20-lts"
    }

    ip_restriction {
      name         = "AllowFrontDoorOnly"
      action       = "Allow"
      priority     = 100
      service_tag  = "AzureFrontDoor.Backend"

      dynamic "headers" {
        for_each = var.front_door_id == "" ? [] : [var.front_door_id]
        content {
          x_azure_fdid = [headers.value]
        }
      }
    }

    ip_restriction {
      name       = "DenyAll"
      action     = "Deny"
      priority   = 2147483647
      ip_address = "0.0.0.0/0"
    }
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"             = "1"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string
    "KEY_VAULT_URI"                        = var.key_vault_uri
    "SQL_CONNECTION_STRING"                = "@Microsoft.KeyVault(SecretUri=${var.key_vault_uri}secrets/${var.sql_connection_string_secret_name}/)"
    "STORAGE_BLOB_ENDPOINT"                = "@Microsoft.KeyVault(SecretUri=${var.key_vault_uri}secrets/${var.storage_blob_endpoint_secret_name}/)"
  }

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true

    http_logs {
      file_system {
        retention_in_days = 30
        retention_in_mb   = 100
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "app" {
  name                       = "diag-app-${var.environment}"
  target_resource_id         = azurerm_linux_web_app.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  enabled_log {
    category = "AppServiceAuditLogs"
  }

  metric {
    category = "AllMetrics"
  }
}
