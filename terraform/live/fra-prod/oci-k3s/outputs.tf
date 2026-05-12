output "server_public_ip" {
  value = oci_core_instance.server.public_ip
}

output "worker_public_ips" {
  value = [for w in oci_core_instance.workers : w.public_ip]
}

output "kubeconfig_fetch" {
  description = "Run this after k3s is installed to fetch kubeconfig"
  value       = "ssh ubuntu@${oci_core_instance.server.public_ip} 'sudo cat /etc/rancher/k3s/k3s.yaml' | sed 's/127.0.0.1/${oci_core_instance.server.public_ip}/g' > ~/.kube/config-oci"
}
