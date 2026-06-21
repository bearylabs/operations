variable "compartment_id" {
  description = "OCI compartment OCID"
  type        = string
  sensitive   = true
}

variable "name_prefix" {
  description = "Prefix for all resource display names (e.g. fra-prod)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "name_prefix must be lowercase alphanumeric and hyphens only."
  }
}

variable "vcn_cidr" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vcn_cidr, 0))
    error_message = "vcn_cidr must be a valid CIDR block."
  }
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr must be a valid CIDR block."
  }
}

variable "common_tags" {
  description = "Freeform tags applied to all resources"
  type        = map(string)
  default     = {}
}
