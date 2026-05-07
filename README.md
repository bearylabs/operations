# operations

Infrastructure mono-repo for homelab k3s clusters. Managed with Terraform, Ansible, and ArgoCD.

## Stack

| Layer | Tool |
|-------|------|
| VM provisioning | Terraform (bpg/proxmox) |
| k3s install | Ansible |
| GitOps | ArgoCD |
| Secrets | Sealed Secrets |
| Load balancer | MetalLB |
| Ingress | Traefik |
| TLS | cert-manager + Let's Encrypt |
| Storage | democratic-csi + TrueNAS SCALE |

## Infrastructure

Proxmox on Intel Mac Mini (16GB RAM). Storage on TrueNAS SCALE (`10.8.10.40`, 225GB pool `nas-01`).

### Network — 10.8.10.0/24

| Range | Purpose |
|-------|---------|
| 10.8.10.0–19 | Network infrastructure |
| 10.8.10.20–39 | Docker Swarm nodes |
| 10.8.10.40–49 | Storage |
| 10.8.10.50–69 | Virtual IPs |
| 10.8.10.70–89 | k3s nodes |
| 10.8.10.90–99 | MetalLB pool (k3s LoadBalancer IPs) |

Gateway: `10.8.10.1` — DNS: `10.8.10.50` (BIND9)

### Clusters

| Cluster | Nodes | Domain | Status |
|---------|-------|--------|--------|
| onprem-prod | 3 (Mac Mini / Proxmox) | `*.prod.beary.cloud` | active |
| onprem-dev | — | `*.dev.beary.cloud` | planned (Raspberry Pi) |
| oci-prod | — | `*.oci.beary.cloud` | on hold (capacity issues) |

### onprem-prod nodes

| Node | IP | Role | vCPU | RAM | k3s |
|------|----|------|------|-----|-----|
| k3s-server | 10.8.10.70 | control plane | 2 | 4GB | v1.32.4 |
| k3s-worker-1 | 10.8.10.71 | worker | 2 | 4GB | v1.32.4 |
| k3s-worker-2 | 10.8.10.72 | worker | 2 | 4GB | v1.32.4 |

## Repository Structure

```
terraform/environments/onprem/   # Proxmox VM provisioning (done)
terraform/environments/oci/      # OCI infra (on hold)
ansible/playbooks/site.yml       # k3s bootstrap playbook
kubernetes/clusters/             # ArgoCD App of Apps entry points per cluster
kubernetes/infrastructure/       # Infrastructure Applications (MetalLB, Traefik, cert-manager, etc.)
kubernetes/apps/                 # Workload Applications
docs/                            # Runbooks and guides
```

## Docs

- [ArgoCD Bootstrap](docs/argocd-bootstrap.md)
- [Sealed Secrets](docs/sealed-secrets.md)
- [cert-manager & TLS](docs/cert-manager.md)
- [DNS Setup](docs/dns.md)
- [Runbook: Add New Service](docs/runbook-new-service.md)
- [Storage](docs/storage.md)
