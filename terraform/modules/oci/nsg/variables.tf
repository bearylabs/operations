variable "compartment_id" {
  description = "OCI compartment OCID"
  type        = string
  sensitive   = true
}

variable "vcn_id" {
  description = "OCID of the VCN to attach the NSG to"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for the NSG display name (e.g. fra-prod-unifi)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "name_prefix must be lowercase alphanumeric and hyphens only."
  }
}

variable "ingress_rules" {
  description = "Map of ingress rules. Key is stable Terraform resource ID — use descriptive names."
  type = map(object({
    protocol = string # "6" = TCP, "17" = UDP
    source   = string # CIDR block
    port_min = number
    port_max = number
  }))
  default = {}
}

variable "common_tags" {
  description = "Freeform tags applied to the NSG"
  type        = map(string)
  default     = {}
}
