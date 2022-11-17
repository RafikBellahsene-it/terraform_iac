resource "azurerm_key_vault" "public_kv" {
  name                          = var.key_vault_name
  location                      = var.key_vault_location
  resource_group_name           = var.rg_name
  enabled_for_disk_encryption   = true
  tenant_id                     = var.tenant_id
  soft_delete_retention_days    = 30
  purge_protection_enabled      = var.is_umi_assigned == true ? true : var.purge_protection_enabled
  sku_name                      = var.sku_name
  tags                          = var.tags
  public_network_access_enabled = true

  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = var.authorized_ip
    virtual_network_subnet_ids = var.authorized_subnet_ids
  }
}


resource "azurerm_key_vault_access_policy" "kv_access_policy" {
  for_each                = var.access_policy_objects
  key_vault_id            = azurerm_key_vault.public_kv.id
  object_id               = each.value.object_id
  secret_permissions      = each.value.secret_permissions
  certificate_permissions = each.value.certificate_permission
  key_permissions         = each.value.key_permissions
  tenant_id               = var.tenant_id
}

resource "azurerm_key_vault_access_policy" "kv_umi_access_policy" {
  count        = var.is_umi_assigned == true ? 1 : 0
  key_vault_id = azurerm_key_vault.public_kv.id
  object_id    = var.umi_principal_id

  key_permissions = [
    "WrapKey",
    "UnwrapKey",
    "Get",
    "Recover",
  ]

  tenant_id = var.tenant_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore"
  ]
}