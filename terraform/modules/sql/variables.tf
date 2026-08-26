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

variable "key_vault_id" {
  type = string
}

variable "aad_admin_login" {
  description = "AAD group or user name set as SQL Server AAD admin (e.g. 'sql-admins')"
  type        = string
}

variable "aad_admin_object_id" {
  type = string
}

variable "sku_name" {
  description = "Database SKU, e.g. GP_S_Gen5_1 (serverless) for dev, GP_Gen5_2 for prod"
  type        = string
  default     = "GP_S_Gen5_1"
}

variable "min_capacity" {
  type    = number
  default = 0.5
}

variable "geo_backup_enabled" {
  type    = bool
  default = true
}
