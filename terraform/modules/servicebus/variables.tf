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

variable "sku" {
  description = "Service Bus SKU - must be Premium for Private Endpoint support"
  type        = string
  default     = "Premium"
}

variable "function_principal_ids" {
  description = "Managed identity principal IDs granted Service Bus data access"
  type        = list(string)
  default     = []
}

variable "max_delivery_count" {
  type    = number
  default = 5
}
