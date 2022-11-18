resource "azurerm_data_factory" "adf" {
  name = var.adf_name
  resource_group_name = var.rg_name
  location = var.location
  managed_virtual_network_enabled = false
  public_network_enabled = true

   identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [var.cmk.user_assigned_identity_id]
  }

  customer_managed_key_id = var.cmk.key_id
  customer_managed_key_identity_id = var.cmk.user_assigned_identity_id

}