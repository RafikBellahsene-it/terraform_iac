
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
  public_network_access_enabled     = true
  is_hns_enabled                    = false
  infrastructure_encryption_enabled = true

  dynamic "customer_managed_key" {
    for_each = (var.encrypt_with_cmk ? var.cmk["storage"] : {})
    content {
      user_assigned_identity_id = customer_managed_key.value.user_assigned_identity_id
      key_vault_key_id          = customer_managed_key.value.key_vault_key_id
    }
  } 

  identity {
    type         = var.encrypt_with_cmk == true ? "UserAssigned" : "SystemAssigned"
    identity_ids = var.encrypt_with_cmk ? [var.cmk["storage"][0].user_assigned_identity_id] : []
  }
}

resource "azurerm_container_registry" "acr" {
  name                          = var.container_registry.name
  resource_group_name           = var.rg_name
  location                      = var.aml_location
  sku                           = var.container_registry.sku
  public_network_access_enabled = true
  identity {
    type         = "SystemAssigned"
  }
}


resource "azurerm_storage_account_network_rules" "storage_network_rule" {
  storage_account_id         = azurerm_storage_account.aml_storage.id
  default_action             = "Allow"
  ip_rules                   = var.public_access.ip_rules
  virtual_network_subnet_ids = var.public_access.subnet_ids
  bypass                     = ["AzureServices"]
}


resource "azurerm_machine_learning_workspace" "aml_ws" {
  name                          = var.aml_ws_name
  resource_group_name           = var.rg_name
  location                      = var.aml_location
  application_insights_id       = azurerm_application_insights.aml_app_insights.id
  key_vault_id                  = var.key_vault_id
  storage_account_id            = azurerm_storage_account.aml_storage.id
  container_registry_id         = azurerm_container_registry.acr.id
  public_network_access_enabled = true
  friendly_name                 = var.aml_ws_name
  high_business_impact          = true
  v1_legacy_mode_enabled        = true
  sku_name                      = "Basic"

  dynamic "encryption" {
    for_each = (var.encrypt_with_cmk ? var.cmk["aml_ws"] : {})
    content {
      key_id                    = encryption.value.key_vault_key_id
      key_vault_id              = encryption.value.key_vault_id
      # user_assigned_identity_id = encryption.value.user_assigned_identity_id
    }
  }

  identity {
    type = "SystemAssigned"
    # type = var.encrypt_with_cmk == true ? "UserAssigned":"SystemAssigned"
  }

}


resource "azurerm_machine_learning_compute_cluster" "aml_compute_clust" {
  depends_on = [
    azurerm_storage_account_network_rules.storage_network_rule
  ]
  name                          = "${var.aml_ws_name}-compute-clust"
  location                      = var.aml_location
  vm_priority                   = "Dedicated"
  vm_size                       = var.cluster.size
  machine_learning_workspace_id = azurerm_machine_learning_workspace.aml_ws.id

  scale_settings {
    min_node_count                       = var.cluster.min_node
    max_node_count                       = var.cluster.max_node
    scale_down_nodes_after_idle_duration = "PT300S"
  }

  identity {
    type = "SystemAssigned"
  }
}

# resource "azurerm_role_assignment" "aml_storage_contrib" {
#   scope                = azurerm_storage_account.aml_storage.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azurerm_machine_learning_workspace.aml_ws.identity[0].principal_id
# }

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

# resource "azurerm_role_assignment" "amlws_kvadmin" {
#   scope                = var.key_vault_id
#   role_definition_name = "Key Vault Administrator"
#   principal_id         = azurerm_machine_learning_workspace.aml_ws.identity[0].principal_id
# }

# resource "azurerm_role_assignment" "amlcompute_acrpull" {
#   scope                = azurerm_container_registry.acr.id
#   role_definition_name = "AcrPull"
#   principal_id         = azurerm_machine_learning_compute_cluster.aml_compute_clust.identity[0].principal_id
# }