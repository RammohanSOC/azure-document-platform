# ---------------------------------------------------------------------------
# Metric alerts. Kept in the root module (not the monitoring module) because
# they reference resource IDs from modules created later in the graph —
# putting them in monitoring.tf would create a dependency cycle.
# ---------------------------------------------------------------------------

resource "azurerm_monitor_metric_alert" "app_5xx" {
  name                = "alert-app-5xx-${var.environment}"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [module.app_service.app_id]
  description         = "App Service 5xx errors exceeded threshold"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
  }

  action {
    action_group_id = module.monitoring.action_group_id
  }
}

resource "azurerm_monitor_metric_alert" "function_failures" {
  for_each = {
    upload  = module.functions.upload_processor_id
    docproc = module.functions.document_processor_id
  }

  name                = "alert-func-failures-${each.key}-${var.environment}"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [each.value]
  description         = "Function reporting execution errors"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5
  }

  action {
    action_group_id = module.monitoring.action_group_id
  }
}

resource "azurerm_monitor_metric_alert" "servicebus_queue_length" {
  name                = "alert-sb-queue-length-${var.environment}"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [module.servicebus.namespace_id]
  description         = "Service Bus active message count exceeded threshold"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.ServiceBus/namespaces"
    metric_name      = "ActiveMessages"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 500
  }

  action {
    action_group_id = module.monitoring.action_group_id
  }
}

resource "azurerm_monitor_metric_alert" "servicebus_dead_letter" {
  name                = "alert-sb-dlq-${var.environment}"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [module.servicebus.namespace_id]
  description         = "Dead-lettered messages present on document-processing queue"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.ServiceBus/namespaces"
    metric_name      = "DeadletteredMessages"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = module.monitoring.action_group_id
  }
}

resource "azurerm_monitor_metric_alert" "sql_cpu" {
  name                = "alert-sql-cpu-${var.environment}"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [module.sql.sql_database_id]
  description         = "SQL Database CPU exceeded threshold"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = module.monitoring.action_group_id
  }
}

resource "azurerm_monitor_metric_alert" "storage_availability" {
  name                = "alert-storage-availability-${var.environment}"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [module.storage.storage_account_id]
  description         = "Storage account availability degraded"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 99
  }

  action {
    action_group_id = module.monitoring.action_group_id
  }
}

resource "azurerm_monitor_metric_alert" "frontdoor_unhealthy_origin" {
  name                = "alert-afd-unhealthy-origin-${var.environment}"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [module.frontdoor.profile_resource_id]
  description         = "Front Door origin health below 100%"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Cdn/profiles"
    metric_name      = "OriginHealthPercentage"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 100
  }

  action {
    action_group_id = module.monitoring.action_group_id
  }
}

resource "azurerm_monitor_metric_alert" "frontdoor_latency" {
  name                = "alert-afd-latency-${var.environment}"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [module.frontdoor.profile_resource_id]
  description         = "Front Door total latency high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Cdn/profiles"
    metric_name      = "TotalLatency"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 2000
  }

  action {
    action_group_id = module.monitoring.action_group_id
  }
}
