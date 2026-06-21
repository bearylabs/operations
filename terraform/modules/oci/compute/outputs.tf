output "public_ip" {
  description = "Public IP address of the instance"
  value       = oci_core_instance.this.public_ip
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = oci_core_instance.this.private_ip
}

output "instance_id" {
  description = "OCID of the instance"
  value       = oci_core_instance.this.id
}
