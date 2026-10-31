# DNS setup

Current production DNS is **CoreDNS at `10.8.10.92`**. The old BIND9 address `10.8.10.50` and former Swarm DNS `10.8.10.20` are retired/unreachable; do not configure new clients to use them.

## Resolution paths

```text
LAN client
  → CoreDNS LoadBalancer 10.8.10.92 (UDP and TCP 53)
      home.beary.cloud       → 10.8.10.90 (Traefik)
      mqtt.beary.cloud       → 10.8.10.91 (Mosquitto)
      nas.beary.cloud        → 10.8.10.40 (TrueNAS)
      *.prod.beary.cloud     → 10.8.10.90
      other names            → 1.1.1.1 / 1.0.0.1

Kubernetes pod
  → K3s cluster DNS 10.43.0.10
      cluster.local          → Kubernetes service discovery
      beary.cloud            → 10.8.10.92 (coredns-custom ConfigMap)
      other names            → node resolver upstreams

Kubernetes node (systemd-resolved)
  beary.cloud                → eth0 DNS 10.8.10.92 (~beary.cloud)
  other names                → global 1.1.1.1 / 1.0.0.1 (~.)
```

The node bootstrap resolver must not depend on a DNS pod starting first. Otherwise pulling DNS/controller images after a reboot can deadlock or cause DNS-related ImagePullBackOff failures. Public registry lookups use independent upstreams; private names still use the LAN resolver.

## GitOps configuration

- `kubernetes/infrastructure/dus-prod/coredns.yaml`: pinned CoreDNS Helm chart.
- `kubernetes/infrastructure/dus-prod/coredns/values.yaml`: LAN DNS records and forwarding.
- `kubernetes/infrastructure/dus-prod/cluster-dns-config.yaml`: Application managing K3s's supported custom DNS ConfigMap in `kube-system`.
- `kubernetes/infrastructure/dus-prod/cluster-dns-config/coredns-custom.yaml`: private-zone forwarding; do not patch K3s's generated Corefile directly.
- `ansible/playbooks/site.yml`, tag `node_dns`: persistent node resolver/networkd configuration. The link override assumes these Ubuntu VMs use netplan's `10-netplan-eth0.network`.
- `terraform/live/dus-prod/proxmox-k3s/vms.tf`: cloud-init DNS address for future provisioning. Existing VM cloud-init seeds were updated to .92 without rebooting the guests.

Keep `use_tcp: true` on the CoreDNS server zones. With Helm chart 1.43.0 this generates both UDP and TCP service/container ports. Removing TCP from a mixed-protocol Service can also trigger client-side strategic-merge patch failures (`spec.ports: Required value`). Validate the rendered Service before changing ports; do not delete/recreate the DNS Service as a shortcut.

```sh
helm pull coredns --repo https://coredns.github.io/helm --version 1.43.0 \
  --untar --untardir /tmp/coredns-lint
helm lint /tmp/coredns-lint/coredns \
  -f kubernetes/infrastructure/dus-prod/coredns/values.yaml
helm template coredns coredns --repo https://coredns.github.io/helm \
  --version 1.43.0 --namespace coredns \
  -f kubernetes/infrastructure/dus-prod/coredns/values.yaml \
  --show-only templates/service.yaml
```

## Public access and TLS

Cloudflare supplies public DNS and DNS-01 challenges. `home.beary.cloud` has a public Cloudflare path through the tunnel, while the LAN override uses Traefik directly. `*.prod.beary.cloud` is intended for private LAN/VPN access; public DNS returning a private address does not make that address internet-routable.

cert-manager deliberately uses explicit public recursive resolvers for DNS-01 verification:

```yaml
extraArgs:
  - --dns01-recursive-nameservers-only
  - --dns01-recursive-nameservers=1.1.1.1:53,8.8.8.8:53
```

This bypasses private-zone overrides when checking public challenge records.

## Tailscale and the maintenance laptop

A stale accepted Tailscale route for `10.8.10.0/24` and split-DNS route for `beary.cloud` caused normal browser access to time out even though the ingress was healthy. Binding curl to WLAN bypassed routing, but did not by itself fix system DNS.

On the laptop, the **Susi** NetworkManager profile now has:

- route `10.8.10.0/24 via 10.8.20.1`;
- policy rule `priority 5200 to 10.8.10.0/24 table 254`, before Tailscale's priority 5270;
- DNS `10.8.10.92`;
- routing-only DNS domains `~prod.beary.cloud`, `~home.beary.cloud`, `~mqtt.beary.cloud`, `~nas.beary.cloud`, which are more specific than Tailscale's `~beary.cloud`.

These changes apply only while that WLAN profile is active; Tailscale and other VPN subnet routes remain enabled. Before/rollback values are recorded privately in the maintenance directory's `laptop-network-before-fix.json`. This is a laptop-side correction, **not** a change to every phone/client or the Tailscale control plane.

On another failing device, check its actual DNS answer and route, including Tailscale and browser secure DNS. Do not infer a Kubernetes outage solely from a client DNS timeout.

## Verification

```sh
ip route get 10.8.10.90
resolvectl query home.beary.cloud home.prod.beary.cloud
curl --fail https://home.beary.cloud/ -o /dev/null
curl --fail https://home.prod.beary.cloud/ -o /dev/null
kubectl get applications.argoproj.io -A
kubectl get pods -A
```

Test DNS on **both UDP and TCP 53** against .92 and private/public DNS from an application pod. Also test Home Assistant's `/api/websocket`: a successful upgrade returns HTTP 101 followed by `auth_required`. This verifies the connection, not a user's authenticated session.
