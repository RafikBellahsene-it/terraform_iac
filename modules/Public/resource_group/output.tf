output "rg_id" {
  description = "Created RG ID"
  value       = azurerm_resource_group.rg.id
}

output "rg_name" {
  description = "Created RG Name"
  value       = azurerm_resource_group.rg.name
}