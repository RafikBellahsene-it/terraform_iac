variable "encrypt_with_cmk" {
  type        = bool
  description = "If set to true à CMK Encrypted AML is provided"
}

variable "aml_ws_name" {
  type        = string
  description = "AML WS Name"
}

variable "rg_name" {
  type        = string
  description = "RG Name that is associated to AML"
}

variable "aml_location" {
  type        = string
  description = "AML Location"
}

variable "key_vault_id" {
  type        = string
  description = "Key Vault Id associated to AML"
}

variable "cmk" {
  type = map(map(object({
    user_assigned_identity_id = string
    key_vault_key_id          = string
    key_vault_id              = string
  })))
}

variable "public_access" {
  type = object({
    ip_rules   = list(string)
    subnet_ids = list(string)
  })

}
variable "app_insight" {
  type = object({
    app_insight_name           = string
    app_insight_type           = string
    daily_data_cap_in_gb       = number
    internet_ingestion_enabled = bool
    internet_query_enabled     = bool
  })
}

variable "storage_account" {
  type = object({
    name                     = string
    account_replication_type = string
  })
}

variable "container_registry" {
  type = object({
    name = string
    sku  = string
  })

}

variable "cluster" {
  type = object({
    size      = string
    min_node  = number
    max_node  = number
  })

}