# Global policies and data sources
# Shared policy definitions, provider versions, or constraints

# Example: Azure Policy data source (uncomment when using)
# data "azurerm_policy_definition" "allowed_locations" {
#   display_name = "Allowed locations"
# }

# Example: Require tags policy (reference for environments)
# Use in environment main.tf to assign policies to subscription/management group

variable "allowed_locations" {
  description = "List of allowed Azure regions for resource deployment"
  type        = list(string)
  default     = []
}

variable "enable_policy_enforcement" {
  description = "Whether to enable policy enforcement"
  type        = bool
  default     = false
}
