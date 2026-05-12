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
| dus-prod | 3 (Mac Mini / Proxmox) | `*.prod.beary.cloud` | active |
| dus-dev | — | `*.dev.beary.cloud` | planned (Raspberry Pi) |
| oci-prod | — | `*.oci.beary.cloud` | on hold (capacity issues) |

### dus-prod nodes

| Node | IP | Role | vCPU | RAM | k3s |
|------|----|------|------|-----|-----|
| dus-cp-01 | 10.8.10.70 | control plane | 2 | 4GB | v1.32.4 |
| dus-worker-01 | 10.8.10.71 | worker | 2 | 4GB | v1.32.4 |
| dus-worker-02 | 10.8.10.72 | worker | 2 | 4GB | v1.32.4 |

## Naming Scheme

IATA airport code + role + index. Location-first, tool-agnostic.

```
{iata}-{role}-{index}     →   dus-cp-01, dus-wk-01, cgn-wk-01
{iata}-{env}              →   dus-prod, dus-dev, fra-prod
```

### Location codes

| Code | Location | Notes |
|------|----------|-------|
| `dus` | Düsseldorf region (Moers) | primary site |
| `oci` | OCI region | use OCI region IATA (e.g. `fra` for Frankfurt) |

Multiple sites same city → add index: `dus1`, `dus2`.

### Role codes

| Code | Role |
|------|------|
| `cp` | control plane |
| `worker` | worker node |
| `ext` | external node — Tailscale-connected, not on controlled network |

### Examples

```
dus-cp-01         control plane, primary site
dus-worker-01     worker, primary site
dus-worker-02     worker, primary site
dus-ext-01        external node (friend's machine, VPS, etc.)
dus-ext-02        second external node
```

### Clusters

```
dus-prod        Proxmox production
dus-dev         Raspberry Pi dev (planned)
fra-prod        OCI production (on hold)
```

## Repository Structure

```
terraform/live/dus-prod/proxmox-k3s/  # Proxmox k3s stack
terraform/live/dus-prod/proxmox-maas/ # Proxmox MAAS stack
terraform/live/fra-prod/oci-k3s/      # OCI k3s stack (on hold)
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
