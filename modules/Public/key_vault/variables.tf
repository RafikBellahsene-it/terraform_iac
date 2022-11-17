
variable "key_vault_name" {
  type        = string
  description = "Key Vault Name"
}

variable "key_vault_location" {
  type        = string
  description = "Key Vault Location"
}

variable "rg_name" {
  type        = string
  description = "RG Name that is associated to KeyVault"
}

variable "tenant_id" {
  type        = string
  description = "The Azure Active Directory tenant ID that should be used for authenticating requests to the key vault"
}

variable "purge_protection_enabled" {
  type        = bool
  description = "Is Purge Protection enabled for this Key Vault? Defaults to false"
  default     = false
}

variable "sku_name" {
  type        = string
  description = "The Name of the SKU used for this Key Vault. Possible values are standard and premium."
}

variable "tags" {
  type = object({
    project             = string
    provisioner         = string
    provisioning_method = string
  })
}

variable "authorized_ip" {
  type        = list(string)
  description = "List of authorized public_ip"
  nullable    = true
  default     = null
}

variable "authorized_subnet_ids" {
  type        = list(string)
  description = "List of authorized subnets"
  nullable    = true
  default     = null
}

variable "access_policy_objects" {
  type = map(object({
    object_id              = string
    secret_permissions     = list(string)
    key_permissions        = list(string)
    certificate_permission = list(string)
  }))

  nullable = true
  default  = null
}

variable "is_umi_assigned" {
  type        = bool
  description = "Is UMI used ?"
}

variable "umi_principal_id" {
  type        = string
  description = "Mandatory IF is_umi_used is set to true"
  nullable    = true

}
