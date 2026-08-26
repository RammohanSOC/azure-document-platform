variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "origin_hostname" {
  description = "App Service default hostname to use as Front Door origin"
  type        = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "waf_mode" {
  description = "Prevention or Detection"
  type        = string
  default     = "Prevention"
}

variable "rate_limit_threshold" {
  type    = number
  default = 200
}
