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

variable "sql_connection_string_secret_name" {
  type    = string
  default = "sql-connection-string"
}

variable "storage_blob_endpoint_secret_name" {
  type    = string
  default = "storage-blob-endpoint"
}

variable "sku_name" {
  type    = string
  default = "P1v3"
}

variable "front_door_id" {
  description = <<-EOT
    Front Door profile resource GUID, used to lock origin access to this specific
    Front Door instance via the X-Azure-FDID header. Leave "" on the FIRST apply
    (Front Door doesn't exist yet -> would be a dependency cycle). After Front Door
    is created, re-apply with -var="front_door_id=<module.frontdoor.front_door_id>"
    to close the restriction. Until then, access is scoped by the AzureFrontDoor.Backend
    service tag only (any tenant's Front Door, not just yours).
  EOT
  type    = string
  default = ""
}
