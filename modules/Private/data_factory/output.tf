output "adf_id" {
    value = azurerm_data_factory.adf.id  
}

output "adf_identity" {
  value = azurerm_data_factory.adf.identity
}

output "self_ir_PrimK" {
  value = var.deploy_self_hosted_IR ? azurerm_data_factory_integration_runtime_self_hosted.self_hosted_IR.primary_authorization_key : "N.A"
}

output "self_ir_SecK" {
  value = var.deploy_self_hosted_IR ? azurerm_data_factory_integration_runtime_self_hosted.self_hosted_IR.secondary_authorization_key : "N.A"
}
