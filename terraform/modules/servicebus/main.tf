resource "azurerm_servicebus_namespace" "this" {
  name                          = "sb-${var.project}-${var.environment}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = var.sku
  capacity                      = var.sku == "Premium" ? 1 : 0
  public_network_access_enabled = false
  minimum_tls_version            = "1.2"
  tags                           = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_servicebus_queue" "document_processing" {
  name         = "document-processing"
  namespace_id = azurerm_servicebus_namespace.this.id

  max_delivery_count                  = var.max_delivery_count
  lock_duration                       = "PT5M" # message lock: 5 minutes
  default_message_ttl                 = "P14D"
  dead_lettering_on_message_expiration = true
  requires_duplicate_detection         = true
  duplicate_detection_history_time_window = "PT10M"
  requires_session                    = false
}

# Dead-letter queue is implicit ($DeadLetterQueue sub-queue of document-processing);
# expose diagnostic + alerting hooks for it via monitoring module using this queue id.

resource "azurerm_private_endpoint" "servicebus" {
  name                = "pe-sb-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-sb"
    private_connection_resource_id = azurerm_servicebus_namespace.this.id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "sb-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

resource "azurerm_role_assignment" "functions_sb_sender" {
  for_each             = toset(var.function_principal_ids)
  scope                = azurerm_servicebus_namespace.this.id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = each.value
}

resource "azurerm_monitor_diagnostic_setting" "servicebus" {
  name                       = "diag-sb-${var.environment}"
  target_resource_id         = azurerm_servicebus_namespace.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "OperationalLogs"
  }

  enabled_log {
    category = "VNetAndIPFilteringLogs"
  }

  metric {
    category = "AllMetrics"
  }
}
