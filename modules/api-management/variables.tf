variable "name" {
  description = "Name of the API Management service"
  type        = string
}

variable "location" {
  type        = string
}

variable "resource_group_name" {
  type        = string
}

variable "publisher_name" {
  description = "Publisher name"
  type        = string
}

variable "publisher_email" {
  description = "Publisher email"
  type        = string
}

variable "sku_name" {
  description = "SKU: Consumption, Developer, Basic, Standard, Premium"
  type        = string
  default     = "Developer"
}

variable "subnet_id" {
  description = "Subnet ID for VNet integration (Premium/Standard)"
  type        = string
  default     = null
}

variable "disable_http2" {
  type    = bool
  default = false
}

variable "tags" {
  type        = map(string)
  default     = {}
}
