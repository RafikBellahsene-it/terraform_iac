output "kv_id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.public_kv.id
}

output "kv_url" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.public_kv.vault_uri
}