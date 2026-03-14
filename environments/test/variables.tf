variable "created_by" {}
variable "environment" {}
variable "requester" {}
variable "ticket_reference" {}
variable "project_name" {}
variable "owner" {}

variable "rg" {
  type = object({
    name     = string
    location = string
  })
}


variable "additional_tags" {
  type    = map(string)
  default = {}
}