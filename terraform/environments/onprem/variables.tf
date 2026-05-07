variable "proxmox_endpoint" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://10.8.10.19:8006/"
}

variable "proxmox_api_token" {
  description = "API token — format: root@pam!terraform=<secret>"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name (check top-left in web UI)"
  type        = string
  default     = "pve"
}

variable "ssh_public_key" {
  description = "SSH public key content for VM access"
  type        = string
}

variable "cluster_name" {
  description = "Name prefix for VMs"
  type        = string
  default     = "k3s"
}
