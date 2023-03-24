# Resource group name
resource_group = "aml-terraform-demo"

# Resource name prefix
prefix = "aml"

# Deployment location
location = "northcentralus"

# Friendly Workspace name
workspace_display_name = "aml-terraform-demo"

# Jumpbox login credentials
jumphost_username = "azureuser"
jumphost_password = "ThisIsNotVerySecure!"

# Deploy Azure Kubernetes Cluster
deploy_aks = false