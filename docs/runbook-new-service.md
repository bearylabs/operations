# Runbook: Add New Service

Step-by-step for deploying a new application to `onprem-prod` via ArgoCD.

## 1. Create app directory

```
kubernetes/apps/onprem-prod/
  my-app/
    application.yaml       # ArgoCD Application
    deployment.yaml        # or Helm values, or kustomization
    service.yaml
    certificate.yaml
    ingressroute.yaml
```

## 2. ArgoCD Application manifest

`kubernetes/apps/onprem-prod/my-app/application.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/bearylabs/operations.git
    targetRevision: HEAD
    path: kubernetes/apps/onprem-prod/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## 3. Add to parent apps Application

Create `kubernetes/clusters/onprem-prod/apps.yaml` if it doesn't exist:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/bearylabs/operations.git
    targetRevision: HEAD
    path: kubernetes/apps/onprem-prod
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Apply once manually:

```bash
kubectl apply -f kubernetes/clusters/onprem-prod/apps.yaml
```

After that, dropping any Application manifest into `kubernetes/apps/onprem-prod/` deploys it automatically.

## 4. TLS certificate

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-app-tls
  namespace: my-app
spec:
  secretName: my-app-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - my-app.prod.beary.cloud
```

## 5. Traefik IngressRoute

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: my-app
  namespace: my-app
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`my-app.prod.beary.cloud`)
      kind: Rule
      services:
        - name: my-app
          port: 80
  tls:
    secretName: my-app-tls
```

## 6. Persistent storage (if needed)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-data
  namespace: my-app
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  storageClassName: truenas-nfs
```

Use `ReadWriteMany` for NFS (multiple pods can mount). See [Storage](storage.md) for details.

## 7. Secrets

Seal any secrets before committing. See [Sealed Secrets](sealed-secrets.md).

## 8. Commit and push

```
feat(apps): add my-app
```

ArgoCD syncs within seconds. Monitor in ArgoCD UI at `https://argocd.prod.beary.cloud`.

## 9. Checklist

- [ ] Application manifest in `kubernetes/apps/onprem-prod/`
- [ ] Namespace set with `CreateNamespace=true`
- [ ] Certificate using `letsencrypt-prod`
- [ ] IngressRoute referencing correct `secretName`
- [ ] No raw secrets committed — use Sealed Secrets
- [ ] DNS resolves: `dig my-app.prod.beary.cloud @10.8.10.50`
