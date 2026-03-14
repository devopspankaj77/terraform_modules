# subscription_id = "a952c7be-2375-401d-b046-6b79e69b7bf9" # set your subscription ID here or via TF_VAR_subscription_id



# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------
rg = {
  name     = "rg-icr-project-terraform-test-eastus"
  location = "eastus"
}

# # -----------------------------------------------------------------------------
# # VNet and Subnets
# # -----------------------------------------------------------------------------
# vnets = {
#   main = {
#     name          = "vnet-myproject-dev"
#     address_space = ["10.0.0.0/16"]
#     create_nsg    = true
#     subnets = {
#       subnet-app = {
#         address_prefixes = ["10.0.1.0/24"]
#       }
#       subnet-data = {
#         address_prefixes = ["10.0.2.0/24"]
#       }
#     }
#   }
# }

created_by       = "Pankaj"
environment      = "dev"
requester        = "Application Team"
ticket_reference = "INC-12345"
project_name     = "Banking-App"
owner            = "platform-team"
