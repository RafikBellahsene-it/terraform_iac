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