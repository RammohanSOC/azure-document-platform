variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "subnet_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "app_insights_connection_string" {
  type = string
}

variable "key_vault_uri" {
  type = string
}

variable "storage_account_name" {
  description = "Storage account backing the Function Apps' own runtime (azure-functions-XXXX container)"
  type        = string
}

# No storage_account_access_key: the storage account has shared_access_key_enabled = false
# (AZ-500 pattern — no long-lived account keys). Function Apps authenticate to their own
# runtime storage via storage_uses_managed_identity instead; each Function App's identity
# needs "Storage Blob Data Owner" + "Storage Account Contributor" on that storage account,
# granted in the root module after both resources exist.

variable "servicebus_namespace_fqdn" {
  type = string
}

variable "servicebus_queue_name" {
  type = string
}

variable "sql_connection_secret_name" {
  type    = string
  default = "sql-connection-string"
}

variable "blob_endpoint_secret_name" {
  type    = string
  default = "storage-blob-endpoint"
}

variable "sku_name" {
  type    = string
  default = "EP1" # Premium plan: required for VNet integration + private endpoint access
}
