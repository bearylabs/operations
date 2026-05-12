variable "tenancy_ocid" {
  description = "OCI tenancy OCID"
  type        = string
}

variable "user_ocid" {
  description = "OCI user OCID"
  type        = string
}

variable "fingerprint" {
  description = "API key fingerprint"
  type        = string
}

variable "private_key_path" {
  description = "Path to OCI API private key (.pem)"
  type        = string
}

variable "region" {
  description = "OCI region identifier (e.g. eu-frankfurt-1)"
  type        = string
}

variable "compartment_ocid" {
  description = "OCI compartment OCID — use tenancy_ocid for root compartment"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key content for instance access"
  type        = string
}

variable "cluster_name" {
  description = "Name prefix applied to all resources"
  type        = string
  default     = "k3s"
}

variable "availability_domain_index" {
  description = "AD index to use (0, 1, or 2). Change if AD-1 has no capacity."
  type        = number
  default     = 0
}
