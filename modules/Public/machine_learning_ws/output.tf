output "app_insight_id" {
  value = azurerm_application_insights.aml_app_insights.id
}

output "app_insight_instrumentation_key" {
  value     = azurerm_application_insights.aml_app_insights.instrumentation_key
  sensitive = true
}

output "app_insight_connection_string" {
  value     = azurerm_application_insights.aml_app_insights.connection_string
  sensitive = true
}

output "storage_account_id" {
  value = azurerm_storage_account.aml_storage.id
}

output "storage_account_primary_blob_endpoint" {
  value = azurerm_storage_account.aml_storage.primary_blob_endpoint
}

output "storage_account_primary_df_endpoint" {
  value = azurerm_storage_account.aml_storage.primary_dfs_endpoint
}

output "storage_account_identity" {
  value = azurerm_storage_account.aml_storage.identity
}

output "container_registry_id" {
  value = azurerm_container_registry.acr.id
}

output "container_registry_identity" {
  value = azurerm_container_registry.acr.identity
}

output "aml_id" {
  value = azurerm_machine_learning_workspace.aml_ws.id
}

output "aml_identity" {
  value = azurerm_machine_learning_workspace.aml_ws.identity
}