resource "azurerm_key_vault" "private_kv" {
  name                        = var.key_vault_name
  location                    = var.key_vault_location
  resource_group_name         = var.rg_name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 30
  purge_protection_enabled    = var.purge_protection_enabled

  sku_name                      = var.sku_name
  tags                          = var.tags
  public_network_access_enabled = false

}

resource "azurerm_key_vault_access_policy" "kv_access_policy" {
  for_each                = var.access_policy_objects
  key_vault_id            = azurerm_key_vault.private_kv.id
  object_id               = each.value.object_id
  secret_permissions      = each.value.secret_permissions
  certificate_permissions = each.value.certificate_permission
  key_permissions         = each.value.key_permissions
  tenant_id               = var.tenant_id
}

resource "azurerm_key_vault_access_policy" "kv_umi_access_policy" {
  count        = var.is_umi_assigned == true ? 1 : 0
  key_vault_id = azurerm_key_vault.private_kv.id
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

resource "azurerm_private_endpoint" "pe-vault" {
  name                = "pe-vault-${var.key_vault_name}"
  location            = var.key_vault_location
  resource_group_name = var.rg_name
  subnet_id           = var.pe_subnet_id

  private_service_connection {
    name                           = "psc-vault-${var.key_vault_name}"
    private_connection_resource_id = azurerm_key_vault.private_kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }
}

resource "azurerm_private_dns_zone" "vault_pv_dns_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vault_pv_dns_zone_vnet_link" {
  name                  = "vnetlink_vaultpvdnszone"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.vault_pv_dns_zone.name
  virtual_network_id    = var.pv_dnszone_vnetid
}

resource "azurerm_private_dns_a_record" "dns_a" {
  name                = var.key_vault_name
  zone_name           = azurerm_private_dns_zone.vault_pv_dns_zone.name
  resource_group_name = var.rg_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe-vault.private_service_connection.0.private_ip_address]
}