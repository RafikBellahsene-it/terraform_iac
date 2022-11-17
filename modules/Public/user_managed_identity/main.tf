resource "azurerm_user_assigned_identity" "umi" {
  location            = var.umi_location
  name                = var.umi_name
  resource_group_name = var.rg_name
}

