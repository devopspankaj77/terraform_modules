variable "name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = null
}

variable "vnet_subnet_id" {
  description = "Subnet ID for the AKS nodes"
  type        = string
  default     = null
}

variable "default_node_pool_name" {
  description = "Name of the default node pool"
  type        = string
  default     = "system"
}

variable "default_node_pool_vm_size" {
  description = "VM size for default node pool. Use a size available in your region/subscription (e.g. Standard_F4s_v2, Standard_DS2_v2). See https://aka.ms/aks/quotas-skus-regions"
  type        = string
  default     = "Standard_F4s_v2"
}

variable "default_node_pool_node_count" {
  description = "Initial node count for default pool"
  type        = number
  default     = 1
}

variable "default_node_pool_enable_auto_scaling" {
  description = "Enable auto scaling for default pool"
  type        = bool
  default     = false
}

variable "default_node_pool_min_count" {
  description = "Minimum node count (when auto scaling)"
  type        = number
  default     = 1
}

variable "default_node_pool_max_count" {
  description = "Maximum node count (when auto scaling)"
  type        = number
  default     = 3
}

variable "enable_azure_rbac" {
  description = "Enable Azure AD RBAC"
  type        = bool
  default     = false
}

variable "azure_rbac_admin_group_object_ids" {
  description = "Azure AD group object IDs for cluster admin"
  type        = list(string)
  default     = []
}

variable "network_plugin" {
  description = "Network plugin (azure or kubenet)"
  type        = string
  default     = "kubenet"
}

variable "network_policy" {
  description = "Network policy (azure, calico, or null)"
  type        = string
  default     = null
}

variable "user_node_pools" {
  description = "Additional user node pools"
  type = map(object({
    vm_size             = string
    node_count          = number
    enable_auto_scaling = bool
    min_count           = optional(number)
    max_count           = optional(number)
    mode                = optional(string, "User")
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
