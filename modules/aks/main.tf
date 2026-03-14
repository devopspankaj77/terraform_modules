# AKS (Azure Kubernetes Service) Module
# Creates AKS cluster with system and optional user node pools

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags

  default_node_pool {
    name                 = var.default_node_pool_name
    vm_size              = var.default_node_pool_vm_size
    node_count           = var.default_node_pool_enable_auto_scaling ? null : var.default_node_pool_node_count
    vnet_subnet_id       = var.vnet_subnet_id
    type                 = "VirtualMachineScaleSets"
    auto_scaling_enabled = var.default_node_pool_enable_auto_scaling
    min_count            = var.default_node_pool_enable_auto_scaling ? var.default_node_pool_min_count : null
    max_count            = var.default_node_pool_enable_auto_scaling ? var.default_node_pool_max_count : null
  }

  identity {
    type = "SystemAssigned"
  }

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.enable_azure_rbac ? [1] : []
    content {
      azure_rbac_enabled     = true
      admin_group_object_ids = var.azure_rbac_admin_group_object_ids
    }
  }

  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    load_balancer_sku = "standard"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user_pools" {
  for_each = var.user_node_pools

  name                    = each.key
  kubernetes_cluster_id   = azurerm_kubernetes_cluster.main.id
  vm_size                 = each.value.vm_size
  node_count              = each.value.enable_auto_scaling ? null : each.value.node_count
  mode                    = each.value.mode
  auto_scaling_enabled    = each.value.enable_auto_scaling
  min_count               = each.value.enable_auto_scaling ? try(each.value.min_count, 1) : null
  max_count               = each.value.enable_auto_scaling ? try(each.value.max_count, 3) : null
}