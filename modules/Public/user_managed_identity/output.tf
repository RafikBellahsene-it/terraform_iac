output "umi_id" {
  value       = azurerm_user_assigned_identity.umi.id
  description = "UMI Resource ID"
}

output "umi_principal_id" {
  value       = azurerm_user_assigned_identity.umi.principal_id
  description = "The ID of the Service Principal object associated with the created Identity"
}

output "umi_client_id" {
  value       = azurerm_user_assigned_identity.umi.client_id
  description = "The ID of the app associated with the Identity"
}

output "umi_tenant_id" {
  value       = azurerm_user_assigned_identity.umi.tenant_id
  description = "The ID of the Tenant which the Identity belongs to."
}