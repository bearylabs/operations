variable "compartment_id" {
  description = "OCI compartment OCID"
  type        = string
  sensitive   = true
}

variable "availability_domain" {
  description = "Full availability domain name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet OCID to attach the instance VNIC to"
  type        = string
}

variable "nsg_ids" {
  description = "List of NSG OCIDs to attach to the instance VNIC"
  type        = list(string)
  default     = []
}

variable "shape" {
  description = "OCI compute shape"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "ocpus" {
  description = "Number of OCPUs (Ampere A1 flex)"
  type        = number
  default     = 2

  validation {
    condition     = var.ocpus >= 1 && var.ocpus <= 4
    error_message = "ocpus must be between 1 and 4 (Always Free limit)."
  }
}

variable "memory_in_gbs" {
  description = "Memory in GB (Ampere A1 flex)"
  type        = number
  default     = 4

  validation {
    condition     = var.memory_in_gbs >= 1 && var.memory_in_gbs <= 24
    error_message = "memory_in_gbs must be between 1 and 24 (Always Free limit)."
  }
}

variable "boot_volume_size_in_gbs" {
  description = "Boot volume size in GB"
  type        = number
  default     = 50

  validation {
    condition     = var.boot_volume_size_in_gbs >= 50 && var.boot_volume_size_in_gbs <= 200
    error_message = "boot_volume_size_in_gbs must be between 50 and 200."
  }
}

variable "image_id" {
  description = "OCI image OCID for the boot volume"
  type        = string
}

variable "hostname" {
  description = "Hostname label for the instance (alphanumeric and hyphens)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.hostname))
    error_message = "hostname must be lowercase alphanumeric and hyphens only."
  }
}

variable "name_prefix" {
  description = "Prefix for the instance display name"
  type        = string
}

variable "user_data" {
  description = "Base64-encoded cloud-init user data"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Freeform tags applied to the instance"
  type        = map(string)
  default     = {}
}
