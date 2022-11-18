variable "adf_name" {
  type = string
  description = "Name of the ADF"
}

variable "rg_name" {
  type = string
  description = "Name of the RG"
}

variable "location" {
  type = string
  description = "Name of the location"
}

variable "cmk" {
  type = object({
    user_assigned_identity_id = string
    key_id = string
  })
}

variable "deploy_self_hosted_IR" {
  type = bool
  description = "If true a self hosted IR is created in the adf portal"
}

variable "pe_subnet_id" {
  type = string
  description = "Subnet ID of the Privat Endpoint"
}

variable "pv_dnszone_vnetid" {
  type = string
  description = "VNET ID"
}