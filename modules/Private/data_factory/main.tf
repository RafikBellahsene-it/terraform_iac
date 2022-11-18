resource "azurerm_data_factory" "adf" {
  name = var.adf_name
  resource_group_name = var.rg_name
  location = var.location
  managed_virtual_network_enabled = true
  public_network_enabled = false

   identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [var.cmk.user_assigned_identity_id]
  }

  customer_managed_key_id = var.cmk.key_id
  customer_managed_key_identity_id = var.cmk.user_assigned_identity_id

}

resource "azurerm_data_factory_integration_runtime_self_hosted" "self_hosted_IR" {
  count = var.deploy_self_hosted_IR ? 1 : 0
  name            = "${var.adf_name}-selfIR"
  data_factory_id = azurerm_data_factory.adf.id
}


resource "azurerm_private_endpoint" "pe-adf" {
  name                = "pe-datafactory-${var.adf_name}"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.pe_subnet_id

  private_service_connection {
    name                           = "psc-datafactory-${var.adf_name}"
    private_connection_resource_id = azurerm_data_factory.adf.id
    is_manual_connection           = false
    subresource_names              = ["dataFactory"]
  }
}

resource "azurerm_private_endpoint" "pe-adfportal" {
  name                = "pe-adfportal-${var.adf_name}"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.pe_subnet_id

  private_service_connection {
    name                           = "psc-adfportal-${var.adf_name}"
    private_connection_resource_id = azurerm_data_factory.adf.id
    is_manual_connection           = false
    subresource_names              = ["portal"]
  }
}

resource "azurerm_private_dns_zone" "adffactory_pv_dns_zone" {
  name                = "privatelink.datafactory.azure.net"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone" "adfportal_pv_dns_zone" {
  name                = "privatelink.adf.azure.com"
  resource_group_name = var.rg_name
}


resource "azurerm_private_dns_zone_virtual_network_link" "adfactory_pv_dns_zone_vnet_link" {
  name                  = "vnetlink_adfactorypvdnszone"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.adffactory_pv_dns_zone.name
  virtual_network_id    = var.pv_dnszone_vnetid
}

resource "azurerm_private_dns_zone_virtual_network_link" "adfportal_pv_dns_zone_vnet_link" {
  name                  = "vnetlink_adfportalpvdnszone"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.adfportal_pv_dns_zone.name
  virtual_network_id    = var.pv_dnszone_vnetid
}

resource "azurerm_private_dns_a_record" "adfportal_dns_a" {
  name                = var.adf_name
  zone_name           = azurerm_private_dns_zone.adfportal_pv_dns_zone.name
  resource_group_name = var.rg_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe-adfportal.private_service_connection.0.private_ip_address]
}

resource "azurerm_private_dns_a_record" "adfactory_dns_a" {
  name                = var.adf_name
  zone_name           = azurerm_private_dns_zone.adffactory_pv_dns_zone.name
  resource_group_name = var.rg_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe-adf.private_service_connection.0.private_ip_address]
}