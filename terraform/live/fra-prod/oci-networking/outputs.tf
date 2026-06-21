output "vcn_id" {
  description = "OCID of the VCN"
  value       = module.networking.vcn_id
}

output "subnet_id" {
  description = "OCID of the public subnet"
  value       = module.networking.subnet_id
}
