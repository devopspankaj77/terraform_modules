# Azure Cache for Redis Module

resource "azurerm_redis_cache" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = var.capacity
  family              = var.family
  sku_name            = var.sku_name
  non_ssl_port_enabled = var.non_ssl_port_enabled
  minimum_tls_version = var.minimum_tls_version
  tags                = var.tags

  redis_configuration {
    maxmemory_policy = var.maxmemory_policy
  }

  dynamic "patch_schedule" {
    for_each = var.patch_schedule != null ? [var.patch_schedule] : []
    content {
      day_of_week    = patch_schedule.value.day_of_week
      start_hour_utc = patch_schedule.value.start_hour_utc
    }
  }
}
