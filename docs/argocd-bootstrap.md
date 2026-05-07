# ArgoCD Bootstrap

## Prerequisites

- `kubectl` configured — `KUBECONFIG=~/.kube/config-onprem`
- Cluster healthy (`kubectl get nodes` all `Ready`)

## Install

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

## Access

Get initial admin password:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath='{.data.password}' | base64 -d && echo
```

Port-forward (no ingress yet — MetalLB/Traefik installed later via ArgoCD):

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open `https://localhost:8080`. Accept self-signed cert warning.
Login: `admin` / password from above.

## Notes

- This is a manual bootstrap step — ArgoCD cannot install itself
- Once running, ArgoCD will manage its own upgrades via a self-referencing Application (future step)
- Traefik and MetalLB are intentionally disabled in k3s install — will be deployed via ArgoCD
