# ArgoCD Bootstrap

Manual one-time bootstrap. After this, ArgoCD manages itself via Git.

## Prerequisites

- `kubectl` configured — `KUBECONFIG=~/.kube/config-onprem`
- Cluster healthy (`kubectl get nodes` all `Ready`)

## 1. Install ArgoCD

Get latest stable version:

```bash
curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep '"tag_name"'
```

Install pinned to that version:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/VERSION/manifests/install.yaml
```

Wait for all pods `Running`:

```bash
kubectl get pods -n argocd --watch
```

Expected pods (7 total):

```
argocd-application-controller-0
argocd-applicationset-controller-*
argocd-dex-server-*
argocd-notifications-controller-*
argocd-redis-*
argocd-repo-server-*
argocd-server-*
```

## 2. Configure insecure mode

Required for TLS termination at Traefik (avoids HTTP→HTTPS redirect loop):

```bash
kubectl patch configmap argocd-cmd-params-cm -n argocd \
  --type merge \
  -p '{"data":{"server.insecure":"true"}}'

kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout status deployment argocd-server -n argocd
```

## 3. Get admin password

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath='{.data.password}' | base64 -d && echo
```

Save this password. Rotate it after first login.

## 4. Bootstrap App of Apps

Apply the root Application once — ArgoCD takes over from here:

```bash
kubectl apply -f kubernetes/clusters/dus-prod/infrastructure.yaml
```

ArgoCD now watches `kubernetes/infrastructure/dus-prod/` and deploys everything automatically.

## 5. Verify (temporary port-forward)

Before ingress is ready:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open `https://localhost:8080`. Accept self-signed cert warning.
Login: `admin` / password from step 3.

After Traefik + cert-manager are deployed, access via `https://argocd.prod.beary.cloud`.

## Notes

- ArgoCD is installed manually — it cannot bootstrap itself
- The `--insecure` flag is safe when Traefik handles TLS
- Future: configure ArgoCD to manage its own Helm release (self-management)
