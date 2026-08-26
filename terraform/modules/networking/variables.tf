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

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.10.0.0/16"]
}

variable "subnet_appservice_cidr" {
  type    = string
  default = "10.10.1.0/24"
}

variable "subnet_functions_cidr" {
  type    = string
  default = "10.10.2.0/24"
}

variable "subnet_pe_cidr" {
  type    = string
  default = "10.10.3.0/24"
}

variable "subnet_firewall_cidr" {
  type    = string
  default = "10.10.4.0/26"
}

variable "enable_firewall" {
  type    = bool
  default = true
}
