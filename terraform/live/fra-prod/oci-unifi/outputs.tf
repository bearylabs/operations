output "public_ip" {
  description = "Public IP of the UniFi controller"
  value       = module.unifi.public_ip
}

output "instance_id" {
  description = "OCID of the UniFi instance"
  value       = module.unifi.instance_id
}

output "unifi_ui_url" {
  description = "UniFi OS Server web UI"
  value       = "https://${module.unifi.public_ip}"
}
