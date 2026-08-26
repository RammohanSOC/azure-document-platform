locals {
  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
    owner       = "cloud-platform-team"
  }
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.project}-${var.environment}"
  location = var.location
  tags     = local.tags
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

module "networking" {
  source = "../../modules/networking"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
  enable_firewall     = var.enable_firewall
}

# ---------------------------------------------------------------------------
# Monitoring core (workspace + app insights + action group) — created early,
# consumed by every other module for diagnostic settings.
# ---------------------------------------------------------------------------

module "monitoring" {
  source = "../../modules/monitoring"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
  alert_email         = var.alert_email
}

# ---------------------------------------------------------------------------
# Key Vault
# ---------------------------------------------------------------------------

module "keyvault" {
  source = "../../modules/keyvault"

  project                    = var.project
  environment                = var.environment
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  tags                       = local.tags
  tenant_id                  = var.tenant_id
  private_endpoint_subnet_id = module.networking.subnet_private_endpoints_id
  private_dns_zone_id        = module.networking.private_dns_zone_ids["keyvault"]
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  admin_object_ids           = var.key_vault_admin_object_ids
}

# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------

module "storage" {
  source = "../../modules/storage"

  project                     = var.project
  environment                 = var.environment
  location                    = var.location
  resource_group_name         = azurerm_resource_group.this.name
  tags                        = local.tags
  private_endpoint_subnet_id  = module.networking.subnet_private_endpoints_id
  private_dns_zone_id         = module.networking.private_dns_zone_ids["blob"]
  log_analytics_workspace_id  = module.monitoring.log_analytics_workspace_id
  app_service_principal_id    = module.app_service.principal_id
  function_principal_ids      = module.functions.function_principal_ids
}

# ---------------------------------------------------------------------------
# SQL
# ---------------------------------------------------------------------------

module "sql" {
  source = "../../modules/sql"

  project                     = var.project
  environment                 = var.environment
  location                    = var.location
  resource_group_name         = azurerm_resource_group.this.name
  tags                        = local.tags
  private_endpoint_subnet_id  = module.networking.subnet_private_endpoints_id
  private_dns_zone_id         = module.networking.private_dns_zone_ids["sql"]
  log_analytics_workspace_id  = module.monitoring.log_analytics_workspace_id
  key_vault_id                = module.keyvault.key_vault_id
  aad_admin_login              = var.aad_admin_login
  aad_admin_object_id          = var.aad_admin_object_id
}

# ---------------------------------------------------------------------------
# Service Bus
# ---------------------------------------------------------------------------

module "servicebus" {
  source = "../../modules/servicebus"

  project                     = var.project
  environment                 = var.environment
  location                    = var.location
  resource_group_name         = azurerm_resource_group.this.name
  tags                        = local.tags
  private_endpoint_subnet_id  = module.networking.subnet_private_endpoints_id
  private_dns_zone_id         = module.networking.private_dns_zone_ids["servicebus"]
  log_analytics_workspace_id  = module.monitoring.log_analytics_workspace_id
  function_principal_ids      = module.functions.function_principal_ids
}

# ---------------------------------------------------------------------------
# App Service (frontend web app)
# ---------------------------------------------------------------------------

module "app_service" {
  source = "../../modules/app-service"

  project                            = var.project
  environment                        = var.environment
  location                           = var.location
  resource_group_name                = azurerm_resource_group.this.name
  tags                               = local.tags
  subnet_id                          = module.networking.subnet_appservice_id
  log_analytics_workspace_id         = module.monitoring.log_analytics_workspace_id
  app_insights_connection_string     = module.monitoring.application_insights_connection_string
  key_vault_uri                      = module.keyvault.key_vault_uri
  front_door_id                      = var.front_door_id # "" on first apply, see variables.tf
}

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

module "functions" {
  source = "../../modules/functions"

  project                         = var.project
  environment                     = var.environment
  location                        = var.location
  resource_group_name             = azurerm_resource_group.this.name
  tags                            = local.tags
  subnet_id                       = module.networking.subnet_functions_id
  log_analytics_workspace_id      = module.monitoring.log_analytics_workspace_id
  app_insights_connection_string  = module.monitoring.application_insights_connection_string
  key_vault_uri                   = module.keyvault.key_vault_uri
  storage_account_name            = module.storage.storage_account_name
  servicebus_namespace_fqdn       = module.servicebus.namespace_fqdn
  servicebus_queue_name           = module.servicebus.queue_name
}

# ---------------------------------------------------------------------------
# Front Door + WAF
# ---------------------------------------------------------------------------

module "frontdoor" {
  source = "../../modules/frontdoor"

  project                    = var.project
  environment                = var.environment
  resource_group_name        = azurerm_resource_group.this.name
  tags                       = local.tags
  origin_hostname            = module.app_service.default_hostname
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
}

# ---------------------------------------------------------------------------
# Extra role assignments: Function Apps share the platform storage account for
# their own runtime (AzureWebJobsStorage via managed identity, no keys). Blob
# Data Contributor is granted in the storage module already; these three cover
# the queue/table/control-plane access the Functions runtime also needs.
# ---------------------------------------------------------------------------

resource "azurerm_role_assignment" "functions_storage_account_contributor" {
  for_each             = toset(module.functions.function_principal_ids)
  scope                = module.storage.storage_account_id
  role_definition_name = "Storage Account Contributor"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "functions_storage_queue" {
  for_each             = toset(module.functions.function_principal_ids)
  scope                = module.storage.storage_account_id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "functions_storage_table" {
  for_each             = toset(module.functions.function_principal_ids)
  scope                = module.storage.storage_account_id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = each.value
}

# App Service also needs Key Vault Secrets User to resolve @Microsoft.KeyVault() references
resource "azurerm_role_assignment" "app_service_kv_secrets_user" {
  scope                = module.keyvault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.app_service.principal_id
}

resource "azurerm_role_assignment" "functions_kv_secrets_user" {
  for_each             = toset(module.functions.function_principal_ids)
  scope                = module.keyvault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

# ---------------------------------------------------------------------------
# SQL connection string secret — consumed by App Service + document-processor
# Function via Key Vault references. Uses Managed Identity / Active Directory
# auth (no SQL login/password in the connection string).
# ---------------------------------------------------------------------------

resource "azurerm_key_vault_secret" "sql_connection_string" {
  name         = "sql-connection-string"
  key_vault_id = module.keyvault.key_vault_id
  value        = "Server=tcp:${module.sql.sql_server_fqdn},1433;Database=${module.sql.sql_database_name};Authentication=Active Directory Managed Identity;"

  depends_on = [azurerm_role_assignment.app_service_kv_secrets_user]
}

resource "azurerm_key_vault_secret" "storage_blob_endpoint" {
  name         = "storage-blob-endpoint"
  key_vault_id = module.keyvault.key_vault_id
  value        = module.storage.primary_blob_endpoint

  depends_on = [azurerm_role_assignment.app_service_kv_secrets_user]
}
