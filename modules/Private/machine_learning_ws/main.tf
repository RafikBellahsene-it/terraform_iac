
resource "azurerm_application_insights" "aml_app_insights" {
  name                       = var.app_insight.app_insight_name
  location                   = var.aml_location
  resource_group_name        = var.rg_name
  application_type           = var.app_insight.app_insight_type
  daily_data_cap_in_gb       = var.app_insight.daily_data_cap_in_gb
  disable_ip_masking         = true
  internet_ingestion_enabled = var.app_insight.internet_ingestion_enabled
  internet_query_enabled     = var.app_insight.internet_query_enabled
}

resource "azurerm_storage_account" "aml_storage" {
  name                              = var.storage_account.name
  location                          = var.aml_location
  resource_group_name               = var.rg_name
  account_tier                      = "Standard"
  account_replication_type          = var.storage_account.account_replication_type
  public_network_access_enabled     = false
  is_hns_enabled                    = true
  infrastructure_encryption_enabled = true

  dynamic "customer_managed_key" {
    for_each = (var.encrypt_with_cmk ? var.cmk["storage"] : {})
    content = {
      user_assigned_identity_id = customer_managed_key.value.user_assigned_identity_id
      key_vault_key_id          = customer_managed_key.value.key_vault_key_id
    }
  }

  identity {
    type         = var.encrypt_with_cmk ? "UserAssigned" : "SystemAssigned"
    identity_ids = var.encrypt_with_cmk ? [var.cmk["storage"].user_assigned_identity_id] : []
  }
}

resource "azurerm_container_registry" "acr" {
  name                          = var.container_registry.name
  resource_group_name           = var.rg_name
  location                      = var.aml_location
  sku                           = var.container_registry.sku
  public_network_access_enabled = false
  identity {
    type         = var.encrypt_with_cmk ? "UserAssigned" : "SystemAssigned"
    identity_ids = var.encrypt_with_cmk ? [var.cmk["acr"].user_assigned_identity_id] : []
  }
  dynamic "encryption" {
    for_each = (var.encrypt_with_cmk ? var.cmk["acr"] : {})
    content = {
      enabled            = true
      key_vault_key_id   = encryption.value.key_vault_key_id
      identity_client_id = var.cmk["acr"].user_assigned_identity_id
    }
  }
}


resource "azurerm_machine_learning_workspace" "aml_ws" {
  name                          = var.aml_ws_name
  resource_group_name           = var.rg_name
  location                      = var.aml_location
  application_insights_id       = azurerm_application_insights.aml_app_insights.id
  key_vault_id                  = var.key_vault_id
  storage_account_id            = azurerm_storage_account.aml_storage.id
  container_registry_id         = azurerm_container_registry.acr.id
  public_network_access_enabled = false
  friendly_name                 = var.aml_ws_name
  high_business_impact          = true
  v1_legacy_mode_enabled        = true
  sku_name                      = "Basic"

  dynamic "encryption" {
    for_each = (var.encrypt_with_cmk ? var.cmk["aml_ws"] : {})
    content = {
      key_id                    = encryption.value.key_vault_key_id
      key_vault_id              = encryption.value.key_vault_id
      user_assigned_identity_id = encryption.value.user_assigned_identity_id
    }
  }

  identity {
    type = "SystemAssigned"
  }

}


resource "azurerm_machine_learning_compute_cluster" "aml_compute_clust" {
  name                          = "${var.aml_ws_name}-compute-clust"
  location                      = var.aml_location
  vm_priority                   = "Dedicated"
  vm_size                       = var.cluster.size
  machine_learning_workspace_id = azurerm_machine_learning_workspace.aml_ws.id
  subnet_resource_id            = var.cluster.subnet_id

  scale_settings {
    min_node_count                       = var.cluster.min_node
    max_node_count                       = var.cluster.max_node
    scale_down_nodes_after_idle_duration = "PT300S" 
  }

  identity {
    type = "SystemAssigned"
  }
}

// ----------------------- Connexion privée de l'ACR -----------------
resource "azurerm_private_endpoint" "pe-acr" {
  name                = "pe-acr-${var.container_registry.name}"
  location            = var.aml_location
  resource_group_name = var.rg_name
  subnet_id           = var.private_endpoints["acr"].subnet_id

  private_service_connection {
    name                           = "psc-acr-${var.container_registry.name}"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }
}

resource "azurerm_private_dns_zone" "acr_pv_dns_zone" {
  name                = "${var.aml_location}.privatelink.azurecr.io"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_pv_dns_zone_vnet_link" {
  name                  = "vnetlink_acrpvdnszone"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.acr_pv_dns_zone.name
  virtual_network_id    = var.private_endpoints["acr"].vnet_id
}

resource "azurerm_private_dns_a_record" "dns_acr" {
  name                = var.container_registry.name
  zone_name           = azurerm_private_dns_zone.acr_pv_dns_zone.name
  resource_group_name = var.rg_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe-acr.private_service_connection.0.private_ip_address]
}


// ----------------------- Connexion privée du stockage -----------------
//                              BLOB
resource "azurerm_private_endpoint" "pe-str-blob" {
  name                = "pe-blob-${var.storage_account.name}"
  location            = var.aml_location
  resource_group_name = var.rg_name
  subnet_id           = var.private_endpoints["storage"].subnet_id

  private_service_connection {
    name                           = "psc-blob-${var.storage_account.name}"
    private_connection_resource_id = azurerm_storage_account.aml_storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}

resource "azurerm_private_endpoint" "pe-str-blob-sec" {
  name                = "pe-blob-sec-${var.storage_account.name}"
  location            = var.aml_location
  resource_group_name = var.rg_name
  subnet_id           = var.private_endpoints["storage"].subnet_id

  private_service_connection {
    name                           = "psc-blob-sec-${var.storage_account.name}"
    private_connection_resource_id = azurerm_storage_account.aml_storage.id
    is_manual_connection           = false
    subresource_names              = ["blob_secondary"]
  }
}

resource "azurerm_private_dns_zone" "strblob_pv_dns_zone" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "strblob_pv_dns_zone_vnet_link" {
  name                  = "vnetlink_strblobpvdnszone"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.strblob_pv_dns_zone.name
  virtual_network_id    = var.private_endpoints["storage"].vnet_id
}

resource "azurerm_private_dns_a_record" "dns_blob" {
  name                = var.storage_account.name
  zone_name           = azurerm_private_dns_zone.strblob_pv_dns_zone.name
  resource_group_name = var.rg_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe-str-blob.private_service_connection.0.private_ip_address,
                        azurerm_private_endpoint.pe-str-blob-sec.private_service_connection.0.private_ip_address]
}


//                              DFS
resource "azurerm_private_endpoint" "pe-str-dfs" {
  name                = "pe-dfs-${var.storage_account.name}"
  location            = var.aml_location
  resource_group_name = var.rg_name
  subnet_id           = var.private_endpoints["storage"].subnet_id

  private_service_connection {
    name                           = "psc-dfs-${var.storage_account.name}"
    private_connection_resource_id = azurerm_storage_account.aml_storage.id
    is_manual_connection           = false
    subresource_names              = ["dfs"]
  }
}

resource "azurerm_private_dns_zone" "strdfs_pv_dns_zone" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "strdfs_pv_dns_zone_vnet_link" {
  name                  = "vnetlink_strdfspvdnszone"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.strdfs_pv_dns_zone.name
  virtual_network_id    = var.private_endpoints["storage"].vnet_id
}

resource "azurerm_private_dns_a_record" "dns_dfs" {
  name                = var.storage_account.name
  zone_name           = azurerm_private_dns_zone.strdfs_pv_dns_zone.name
  resource_group_name = var.rg_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe-str-dfs.private_service_connection.0.private_ip_address]
}

// ----------------------- Connexion privée de l'AML -----------------
resource "azurerm_private_endpoint" "pe-aml" {
  name                = "pe-amlworkspace-${var.aml_ws_name}"
  location            = var.aml_location
  resource_group_name = var.rg_name
  subnet_id           = var.private_endpoints["aml"].subnet_id

  private_service_connection {
    name                           = "psc-amlworkspace-${var.aml_ws_name}"
    private_connection_resource_id = azurerm_machine_learning_workspace.aml_ws.id
    is_manual_connection           = false
    subresource_names              = ["amlworkspace"]
  }
}

resource "azurerm_private_dns_zone" "amlapi_pv_dns_zone" {
  name                = "privatelink.api.azureml.ms"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone" "amlnotebook_pv_dns_zone" {
  name                = "privatelink.notebooks.azure.net"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "amlapi_pv_dns_zone_vnet_link" {
  name                  = "vnetlink_amlapipvdnszone"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.amlapi_pv_dns_zone.name
  virtual_network_id    = var.private_endpoints["acr"].vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "amlnotebook_pv_dns_zone_vnet_link" {
  name                  = "vnetlink_amlnotebookpvdnszone"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.amlnotebook_pv_dns_zone.name
  virtual_network_id    = var.private_endpoints["acr"].vnet_id
}

resource "azurerm_private_dns_a_record" "dns_amlapi" {
  name                = var.aml_ws_name
  zone_name           = azurerm_private_dns_zone.amlapi_pv_dns_zone.name
  resource_group_name = var.rg_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe-aml.private_service_connection.0.private_ip_address]
}

resource "azurerm_private_dns_a_record" "dns_amlnotebook" {
  name                = var.aml_ws_name
  zone_name           = azurerm_private_dns_zone.amlnotebook_pv_dns_zone.name
  resource_group_name = var.rg_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe-aml.private_service_connection.0.private_ip_address]
}


resource "azurerm_role_assignment" "aml_storage_contrib" {
  scope                = azurerm_storage_account.aml_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_machine_learning_workspace.aml_ws.identity[0].principal_id
}

resource "azurerm_role_assignment" "amlcompute_storage_contrib" {
  scope                = azurerm_storage_account.aml_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_machine_learning_compute_cluster.aml_compute_clust.identity[0].principal_id
}

resource "azurerm_role_assignment" "amlcompute_contrib_ws" {
  scope                = azurerm_machine_learning_workspace.aml_ws.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_machine_learning_compute_cluster.aml_compute_clust.identity[0].principal_id
}

resource "azurerm_role_assignment" "amlws_kvadmin" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Administrator"
  principal_id         = azurerm_machine_learning_workspace.aml_ws.identity[0].principal_id
}

resource "azurerm_role_assignment" "amlcompute_acrpull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_machine_learning_compute_cluster.aml_compute_clust.identity[0].principal_id
}