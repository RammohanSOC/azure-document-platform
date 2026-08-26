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

variable "private_endpoint_subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "app_service_principal_id" {
  description = "Managed identity principal ID of the App Service, granted Storage Blob Data Contributor"
  type        = string
  default     = null
}

variable "function_principal_ids" {
  description = "Managed identity principal IDs of Function Apps, granted Storage Blob Data Contributor"
  type        = list(string)
  default     = []
}
