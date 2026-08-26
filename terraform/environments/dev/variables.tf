variable "project" {
  type    = string
  default = "docplat"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "centralindia"
}

variable "tenant_id" {
  type = string
}

variable "aad_admin_login" {
  description = "AAD group name for SQL admins, e.g. 'sql-admins-dev'"
  type        = string
}

variable "aad_admin_object_id" {
  description = "Object ID of the AAD group/user set as SQL AAD admin"
  type        = string
}

variable "key_vault_admin_object_ids" {
  description = "Object IDs (pipeline SP + break-glass users/groups) granted Key Vault Administrator"
  type        = list(string)
}

variable "alert_email" {
  type = string
}

variable "enable_firewall" {
  type    = bool
  default = true
}

variable "front_door_id" {
  description = "Set after first apply to lock App Service origin access to this Front Door instance. See app-service module note."
  type        = string
  default     = ""
}
