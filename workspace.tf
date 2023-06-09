# Copyright (c) 2021 Microsoft
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Azure Machine Learning Workspace with Private Link

resource "azurerm_machine_learning_workspace" "aml_ws" {
  name                    = "${var.prefix}-ws-${random_string.postfix.result}"
  friendly_name           = var.workspace_display_name
  location                = azurerm_resource_group.aml_rg.location
  resource_group_name     = azurerm_resource_group.aml_rg.name
  application_insights_id = azurerm_application_insights.aml_ai.id
  key_vault_id            = azurerm_key_vault.aml_kv.id
  storage_account_id      = azurerm_storage_account.aml_sa.id
  container_registry_id   = azurerm_container_registry.aml_acr.id

  identity {
    type = "SystemAssigned"
  }
}

# Create Compute Resources in AML

resource "azurerm_machine_learning_compute_instance" "jump_mustang_instance" {
  name                          = "jump-mustang-instance"
  location                      = azurerm_resource_group.aml_rg.location
  machine_learning_workspace_id = azurerm_machine_learning_workspace.aml_ws.id
  virtual_machine_size          = "STANDARD_DS2_V2"
  authorization_type            = "personal"
  # ssh {
  #   public_key = var.ssh_key
  # }
  subnet_resource_id = azurerm_subnet.compute_subnet.id
  description        = "foo"
  tags = {
    foo = "bar"
  }
}

# DNS Zones

resource "azurerm_private_dns_zone" "ws_zone_api" {
  name                = "privatelink.api.azureml.ms"
  resource_group_name = azurerm_resource_group.aml_rg.name
}

resource "azurerm_private_dns_zone" "ws_zone_notebooks" {
  name                = "privatelink.notebooks.azure.net"
  resource_group_name = azurerm_resource_group.aml_rg.name
}

# Linking of DNS zones to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "ws_zone_api_link" {
  name                  = "${random_string.postfix.result}_link_api"
  resource_group_name   = azurerm_resource_group.aml_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.ws_zone_api.name
  virtual_network_id    = azurerm_virtual_network.aml_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "ws_zone_notebooks_link" {
  name                  = "${random_string.postfix.result}_link_notebooks"
  resource_group_name   = azurerm_resource_group.aml_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.ws_zone_notebooks.name
  virtual_network_id    = azurerm_virtual_network.aml_vnet.id
}

# Private Endpoint configuration

resource "azurerm_private_endpoint" "ws_pe" {
  name                = "${var.prefix}-ws-pe-${random_string.postfix.result}"
  location            = azurerm_resource_group.aml_rg.location
  resource_group_name = azurerm_resource_group.aml_rg.name
  subnet_id           = azurerm_subnet.aml_subnet.id

  private_service_connection {
    name                           = "${var.prefix}-ws-psc-${random_string.postfix.result}"
    private_connection_resource_id = azurerm_machine_learning_workspace.aml_ws.id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-ws"
    private_dns_zone_ids = [azurerm_private_dns_zone.ws_zone_api.id, azurerm_private_dns_zone.ws_zone_notebooks.id]
  }

  # Add Private Link after we configured the workspace and attached AKS
  depends_on = [azurerm_machine_learning_compute_instance.jump_mustang_instance, azurerm_kubernetes_cluster.aml_aks]
}
