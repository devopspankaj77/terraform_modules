# UAT — configuration values only

environment         = "uat"
organization_name   = "myorg"
project_name        = "terraform-enterprise"
owner               = "platform-team"
location            = "eastus"
resource_group_name = "myorg-uat-rg"

vnet_address_space = ["10.1.0.0/16"]
vnet_subnets = {
  default = { address_prefixes = ["10.1.1.0/24"] }
  aks     = { address_prefixes = ["10.1.2.0/24"] }
}

storage_account_tier             = "Standard"
storage_account_replication_type = "LRS"

app_service_sku_name = "B1"
redis_sku_name       = "Basic"

additional_tags = {
  CostCenter = "uat"
}
