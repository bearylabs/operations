# Sealed Secrets

Secrets are encrypted with `kubeseal` before committing to Git. Only the in-cluster Sealed Secrets controller can decrypt them.

## Controller details

| Setting | Value |
|---------|-------|
| Namespace | `sealed-secrets` |
| Controller name | `sealed-secrets` |
| Helm chart | `2.18.5` |

## Seal a secret

Always use `--controller-name` and `--controller-namespace` — the defaults differ from our install:

```bash
kubectl create secret generic <secret-name> \
  --namespace <target-namespace> \
  --from-literal=<key>=<value> \
  --dry-run=client -o yaml | \
  kubeseal \
    --controller-name sealed-secrets \
    --controller-namespace sealed-secrets \
    --format yaml > <secret-name>-sealed.yaml
```

## Examples

### Single literal value

```bash
kubectl create secret generic my-api-key \
  --namespace my-app \
  --from-literal=api-key=supersecret \
  --dry-run=client -o yaml | \
  kubeseal \
    --controller-name sealed-secrets \
    --controller-namespace sealed-secrets \
    --format yaml > my-api-key-sealed.yaml
```

### From file

```bash
kubectl create secret generic my-tls \
  --namespace my-app \
  --from-file=tls.crt=./cert.pem \
  --from-file=tls.key=./key.pem \
  --dry-run=client -o yaml | \
  kubeseal \
    --controller-name sealed-secrets \
    --controller-namespace sealed-secrets \
    --format yaml > my-tls-sealed.yaml
```

### Multiple literals

```bash
kubectl create secret generic db-credentials \
  --namespace my-app \
  --from-literal=username=admin \
  --from-literal=password=supersecret \
  --dry-run=client -o yaml | \
  kubeseal \
    --controller-name sealed-secrets \
    --controller-namespace sealed-secrets \
    --format yaml > db-credentials-sealed.yaml
```

## Commit sealed secrets

Safe to commit `*-sealed.yaml` files. Never commit raw `Secret` manifests.

Add to `.gitignore` to avoid accidents:

```
*-secret.yaml
*-secrets.yaml
```

## Rotate a sealed secret

1. Create new secret with updated value
2. Seal it again with `kubeseal`
3. Overwrite the existing sealed file
4. Commit — ArgoCD syncs the update automatically

## Verify decryption

```bash
kubectl get secret <secret-name> -n <namespace>
```

If the secret exists, the controller decrypted it successfully.
