output "aks_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "aks_fqdn" {
  description = "FQDN of the AKS cluster API server"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "kube_config_raw" {
  description = "Raw kube config (sensitive)"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "kube_config" {
  description = "Kube config block"
  value       = azurerm_kubernetes_cluster.main.kube_config
  sensitive   = true
}

output "node_resource_group" {
  description = "Resource group name for AKS node resources"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}
