# DNS Setup

Split-horizon DNS — Cloudflare for public resolution and cert challenges, BIND9 for local LAN resolution.

## Architecture

```
LAN client
  └── queries BIND9 (10.8.10.50)
        ├── *.prod.beary.cloud → 10.8.10.90  (local override)
        └── everything else → forwards to upstream

Let's Encrypt
  └── queries Cloudflare DNS
        └── _acme-challenge.*.prod.beary.cloud (TXT, created by cert-manager)
```

## Cloudflare records

| Type | Name | Value | Proxy |
|------|------|-------|-------|
| A | `*.prod` | `10.8.10.90` | DNS only |

Note: `10.8.10.90` is a private IP — only resolves from LAN or VPN. The record exists in Cloudflare so cert-manager can do DNS-01 challenges.

## BIND9 local override

Zone file: `/etc/bind/zones/db.prod.beary.cloud`

```zone
$TTL 86400
@   IN  SOA ns1.prod.beary.cloud. admin.beary.cloud. (
            2024010101  ; Serial — increment on every change
            3600
            1800
            604800
            86400 )

@   IN  NS   ns1.prod.beary.cloud.
ns1 IN  A    10.8.10.50

*   IN  A    10.8.10.90
```

Zone declaration in `/etc/bind/named.conf.local`:

```
zone "prod.beary.cloud" {
    type master;
    file "/etc/bind/zones/db.prod.beary.cloud";
};
```

Reload after changes:

```bash
sudo named-checkzone prod.beary.cloud /etc/bind/zones/db.prod.beary.cloud
sudo systemctl reload bind9
```

## Adding a new cluster

For each new cluster, add:

1. Cloudflare A record: `*.dev` → cluster Traefik IP
2. New BIND9 zone for `dev.beary.cloud` following same pattern
3. MetalLB IP pool in cluster config
4. Traefik Helm value pinning the LoadBalancer IP

## Cluster → domain mapping

| Cluster | Domain | Traefik IP |
|---------|--------|------------|
| dus-prod | `*.prod.beary.cloud` | `10.8.10.90` |
| onprem-dev | `*.dev.beary.cloud` | TBD (Raspberry Pi) |
| oci-prod | `*.oci.beary.cloud` | TBD |

## Split-horizon caveat with cert-manager

BIND9 is authoritative for `prod.beary.cloud` locally. cert-manager uses cluster DNS (CoreDNS → BIND9) by default. BIND9 does not have `_acme-challenge` TXT records — only Cloudflare does. This causes DNS-01 challenges to hang indefinitely.

**Fix applied in cert-manager Helm values:**

```yaml
extraArgs:
  - --dns01-recursive-nameservers-only
  - --dns01-recursive-nameservers=1.1.1.1:53,8.8.8.8:53
```

cert-manager now uses Cloudflare/Google DNS for TXT record verification, bypassing BIND9. This must be set for any cluster with local authoritative DNS.

## Verify DNS resolution

```bash
# Local resolution via BIND9
dig argocd.prod.beary.cloud @10.8.10.50

# Public resolution via Cloudflare
dig argocd.prod.beary.cloud @1.1.1.1
```

Both should return the same IP.
