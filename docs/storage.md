# Storage

Persistent storage via democratic-csi backed by TrueNAS SCALE. Dynamic provisioning — PVC creation automatically creates a ZFS dataset and NFS share on TrueNAS.

## Setup

| Setting | Value |
|---------|-------|
| TrueNAS IP | `10.8.10.40` |
| TrueNAS version | SCALE 25.10 (Fangtooth) |
| ZFS pool | `nas-01` |
| NFS parent dataset | `nas-01/nfs/k8s/dus-prod` |
| iSCSI parent dataset | `nas-01/block/k8s/dus-prod` (future) |
| democratic-csi chart | `0.15.1` |

## Storage classes

| Class | Provisioner | Access modes | Default |
|-------|-------------|--------------|---------|
| `truenas-nfs` | `org.democratic-csi.nfs` | RWO, RWX | ✅ |
| `local-path` | `rancher.io/local-path` | RWO | ❌ |

Use `truenas-nfs` for all workloads. Use `local-path` only for node-local scratch data that doesn't need to survive pod rescheduling.

## Create a PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-data
  namespace: my-app
spec:
  accessModes:
    - ReadWriteMany    # NFS supports multiple pods
  resources:
    requests:
      storage: 5Gi
  storageClassName: truenas-nfs
```

## Access modes

| Mode | Meaning | NFS support |
|------|---------|-------------|
| `ReadWriteOnce` (RWO) | One pod, read/write | ✅ |
| `ReadWriteMany` (RWX) | Many pods, read/write | ✅ |
| `ReadOnlyMany` (ROX) | Many pods, read only | ✅ |

Use `ReadWriteMany` when multiple replicas of a pod need the same volume.

## TrueNAS dataset layout

Each PVC creates a child dataset under the parent:

```
nas-01/
  nfs/
    k8s/
      dus-prod/
        pvc-478cd1c3-e711-4a8e-a498-a6159114436f/   ← auto-created per PVC
        pvc-.../
```

## Node prerequisites

All k3s nodes require `nfs-common` — already in Ansible playbook (`ansible/playbooks/site.yml`).

## TrueNAS API key rotation

The TrueNAS API key is stored as a Sealed Secret in:
`kubernetes/infrastructure/dus-prod/democratic-csi-nfs/sealed-secret.yaml`

To rotate:
1. Create new API key in TrueNAS (`user icon → API Keys → Add`)
2. Seal new config (see [Sealed Secrets](sealed-secrets.md))
3. Re-create the secret with new config, seal, overwrite file, commit
4. ArgoCD syncs — democratic-csi restarts with new key

## Debug

```bash
# Check CSI driver pods
kubectl get pods -n democratic-csi

# Check PVC status
kubectl describe pvc <name> -n <namespace>

# Check PV was created
kubectl get pv

# Check events on stuck PVC
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

## Fish shell note

Fish shell does not support `<<EOF` heredocs. Write manifests to a temp file instead:

```bash
# Write to temp file
cat > /tmp/pvc.yaml
# ... paste content, then Ctrl+D
kubectl apply -f /tmp/pvc.yaml
rm /tmp/pvc.yaml
```
