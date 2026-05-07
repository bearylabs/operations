output "server_ip" {
  value = "10.8.10.70"
}

output "worker_ips" {
  value = { for k, v in local.workers : k => v.ip }
}

output "kubeconfig_fetch" {
  description = "Run after k3s is installed"
  value       = "ssh ubuntu@10.8.10.70 'sudo cat /etc/rancher/k3s/k3s.yaml' | sed 's/127.0.0.1/10.8.10.70/g' > ~/.kube/config-onprem"
}
