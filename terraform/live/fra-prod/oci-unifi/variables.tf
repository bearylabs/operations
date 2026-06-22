variable "tenancy_ocid" {
  description = "OCI tenancy OCID"
  type        = string
  sensitive   = true
}

variable "user_ocid" {
  description = "OCI user OCID"
  type        = string
  sensitive   = true
}

variable "fingerprint" {
  description = "OCI API key fingerprint"
  type        = string
  sensitive   = true
}

variable "private_key_path" {
  description = "Path to OCI API private key (.pem)"
  type        = string
}

variable "region" {
  description = "OCI region (e.g. eu-frankfurt-1)"
  type        = string

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+-[0-9]+$", var.region))
    error_message = "region must follow OCI region format (e.g. eu-frankfurt-1)."
  }
}

variable "compartment_id" {
  description = "OCI compartment OCID"
  type        = string
  sensitive   = true
}

variable "tailscale_auth_key" {
  description = "Tailscale one-time auth key (admin console → Settings → Keys → Auth Keys)"
  type        = string
  sensitive   = true
}

variable "availability_domain_index" {
  description = "AD index (0-2). Increment if capacity unavailable in current AD."
  type        = number
  default     = 0

  validation {
    condition     = var.availability_domain_index >= 0 && var.availability_domain_index <= 2
    error_message = "availability_domain_index must be 0, 1, or 2."
  }
}

variable "networking_state_bucket" {
  description = "S3 bucket name holding the oci-networking remote state"
  type        = string
}

variable "networking_state_region" {
  description = "AWS region of the S3 state bucket"
  type        = string
  default     = "eu-central-1"
}

variable "unifi_deb_url" {
  description = "Download URL for UniFi OS Server arm64 installer (from ui.com/download/software/unifi-os-server)"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for the domain hosting the UniFi DNS record"
  type        = string
  sensitive   = true
}

variable "dns_record_name" {
  description = "DNS name for the UniFi controller (e.g. unifi.beary.cloud)"
  type        = string
}
