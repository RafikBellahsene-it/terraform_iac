variable "rg_name" {
  type        = string
  description = "Resource Group Name"
}

variable "rg_location" {
  type        = string
  description = "Resource Group Location"
}

variable "tags" {
  type = object({
    project             = string
    provisioner         = string
    provisioning_method = string
  })
  description = "RG Tags"
}