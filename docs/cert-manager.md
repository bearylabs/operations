# cert-manager & TLS

Certificates are issued automatically via Let's Encrypt DNS-01 challenge using the Cloudflare API.

## ClusterIssuers

| Name | Environment | Rate limits |
|------|-------------|-------------|
| `letsencrypt-staging` | Testing | None — use for new setups |
| `letsencrypt-prod` | Production | 5 certs/domain/week |

Always test with staging first, then switch to prod.

## Add a certificate for a new service

Create a `Certificate` resource in the same namespace as the service:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-service-tls
  namespace: my-service-namespace
spec:
  secretName: my-service-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - my-service.prod.beary.cloud
```

Reference `secretName` in the Traefik `IngressRoute`:

```yaml
tls:
  secretName: my-service-tls
```

## Switch staging → production

Change `issuerRef.name` in the Certificate manifest:

```yaml
issuerRef:
  name: letsencrypt-prod   # was: letsencrypt-staging
  kind: ClusterIssuer
```

Commit and push — cert-manager reissues automatically. Old cert stays valid until new one is ready.

## Debug a stuck certificate

```bash
# Check certificate status
kubectl describe certificate <name> -n <namespace>

# Check certificate request
kubectl get certificaterequest -n <namespace>
kubectl describe certificaterequest <name> -n <namespace>

# Check ACME order
kubectl get order -n <namespace>
kubectl describe order <name> -n <namespace>

# Check DNS-01 challenge
kubectl get challenge -n <namespace>
kubectl describe challenge <name> -n <namespace>
```

Common issues:
- `DNS record not yet propagated` — wait 2-5 min, Cloudflare TXT record needs time
- `Secret does not exist` — normal initial state, cert is being issued
- Challenge stuck → check Cloudflare API token secret exists: `kubectl get secret cloudflare-api-token -n cert-manager`

## Cloudflare API token

Stored as a Sealed Secret in `kubernetes/infrastructure/dus-prod/cert-manager-config/cloudflare-api-token-sealed.yaml`.

Token permissions required: `Zone:DNS:Edit` scoped to `beary.cloud`.

To rotate: create new token in Cloudflare, seal it, overwrite the file, commit.
