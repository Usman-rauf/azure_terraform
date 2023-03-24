# Copyright (c) 2021 Microsoft
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

resource "azurerm_resource_group" "aml_rg" {
  name     = "aml-terraform-demo"
  location = "northcentralus"
}
