variable "vnet_name" {
  type        = string
  description = "Name of the VNET"
}

variable "vnet_location" {
  type        = string
  description = "Location of the VNET"
}

variable "rg_name" {
  type        = string
  description = "Name of the RG where is instanciated the VNET"
}

variable "address_space" {
  type        = list(string)
  Description = "List of adress spaces of the VNET"
}


variable "subnet_list" {
  type = map(object({
    subnet_name                                   = string
    address_space                                 = list(string)
    private_endpoint_network_policies_enabled     = bool
    private_link_service_network_policies_enabled = bool
    service_endpoints                             = list(string)
    delegation = map(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    }))
  }))
}
