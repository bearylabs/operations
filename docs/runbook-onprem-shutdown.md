# On-prem maintenance: shutdown and restart

Prepared 2026-10-31. **Shutdown executed 13:00–13:09 CET; services restored 14:24–14:27 CET on the same day. All 29 Kubernetes pods were verified Running/Ready after recovery. See execution and recovery records below.**

## Access and private recovery material

Private directory on the maintenance laptop (outside Git):

```text
/home/hrudek/.local/state/operations-maintenance/20261031-123006/
```

Contains live inventory, original replica counts (`replicas-before.json`), ArgoCD state, VM configuration, an online k3s SQLite backup with the matching server token, and a readable archive of fluiddpi's printer configuration (18 archive entries). Treat this whole directory as sensitive: the datastore includes Kubernetes Secrets and the directory also contains a TrueNAS API credential. Do not commit or publish it. Directory mode is 0700; files are restricted to the owner.

The SQLite backup was downloaded and passed `PRAGMA integrity_check`. This is **not** a restore rehearsal, full VM backup, or backup of Home Assistant/Mosquitto NFS data. No application-consistent NFS backup or full TrueNAS configuration backup has been made in this preparation.

Access helper (Python; does not require Bash/Fish shell functions):

```sh
python /home/hrudek/.local/state/operations-maintenance/20261031-123006/access.py kubectl get nodes -o wide
python /home/hrudek/.local/state/operations-maintenance/20261031-123006/access.py ssh pve 'qm list'
python /home/hrudek/.local/state/operations-maintenance/20261031-123006/access.py ssh cp 'hostname'
python /home/hrudek/.local/state/operations-maintenance/20261031-123006/access.py ssh worker01 'hostname'
python /home/hrudek/.local/state/operations-maintenance/20261031-123006/access.py ssh worker02 'hostname'
python /home/hrudek/.local/state/operations-maintenance/20261031-123006/access.py ssh fluiddpi 'hostname'
python /home/hrudek/.local/state/operations-maintenance/20261031-123006/truenas-read.py pool
```

The helpers bind upstream connections to `wlp2s0`, bypassing the broken Tailscale subnet route without changing routing. Kubernetes uses a loopback-only TCP forward at `127.0.0.1:16443`; the helper starts it if absent. TLS verification uses the real API address `10.8.10.70`. Kubeconfig: `~/.kube/config-dus-prod-local`; original kubeconfig unchanged. SSH verifies existing host keys. These helpers depend on this laptop, its WLAN, existing keys and kubeconfig; they are not a remote recovery console.

The read-only TrueNAS helper uses the existing CSI API key, stored locally with mode 0600 so NAS inspection does not depend on Kubernetes remaining available. It uses the existing CSI REST transport (HTTP on the trusted server network); it never prints the key. Shutdown permissions have **not** been tested by issuing a shutdown request. TrueNAS GUI/admin access or confirmed authorized API shutdown remains a final gate.

## Verified live inventory

| System | Address / ID | Verified state and access |
|---|---|---|
| EdgeOS gateway | 10.8.10.1 | HTTP/HTTPS, SSH and DNS answer; SSH login not established |
| Network device, identity unresolved | 10.8.10.2 | Dropbear SSH; login not established |
| Network device, identity unresolved | 10.8.10.3 | Dropbear SSH; host key not trusted; not bypassed |
| Network device, identity unresolved | 10.8.10.4 | Dropbear SSH; host key not trusted; not bypassed |
| Proxmox `pve` | 10.8.10.19 | Root SSH via `k3s_onprem`; version 9.1.9; only three active VMs; no containers; no NFS mounts |
| TrueNAS `dc1-nas-01` | 10.8.10.40 | REST read access; SCALE 25.10.2.1; pool `nas-01` ONLINE and healthy; no running apps/VMs/instances returned |
| `dus-cp-01` | 10.8.10.70 / VM 200 | Ready; SSH + passwordless sudo; guest agent responds |
| `dus-worker-01` | 10.8.10.71 / VM 201 | Ready; SSH + passwordless sudo; guest agent responds; Home Assistant NFS client |
| `dus-worker-02` | 10.8.10.72 / VM 202 | Ready; SSH + passwordless sudo; guest agent responds; Mosquitto NFS client |
| Ubuntu template | VM 9000 | Already stopped; no shutdown action needed |
| Traefik | 10.8.10.90 | Virtual Kubernetes service, not a separate machine |
| Mosquitto | 10.8.10.91 | Virtual Kubernetes service, not a separate machine |
| CoreDNS | 10.8.10.92 | Virtual Kubernetes service; UDP DNS query answered |
| `fluiddpi` / 3D-printer controller | 10.8.10.100 | SSH + passwordless sudo; Klipper/Moonraker active; last print complete and heater targets zero at inspection |
| Unidentified device | 10.8.10.231 | Dropbear SSH; host key not trusted; not bypassed |

All three nodes run K3s v1.35.4+k3s1. VM disks are local to Proxmox (`local-lvm`), not on TrueNAS. TrueNAS is not a VM on this Proxmox host; its exact physical/virtual hosting elsewhere is not established.

Port discovery tested TCP 22/80/443/8006/2049 on 10.8.10.1–254. Silence does not prove a host is absent. No responding Swarm hosts were found in 10.8.10.20–39 on those ports. Other VLANs, powered-off devices, and devices exposing other ports are not fully inventoried.

### Storage and backup findings

- Three bound PVCs, all `truenas-nfs`: `homeassistant-config`, `mosquitto-data`, `mosquitto-log`.
- **PV reclaim policy is `Delete`: do not delete PVCs/PVs, uninstall charts, delete ArgoCD Applications, or use Terraform destroy.**
- TrueNAS NFSv4 client inventory showed only workers .71 and .72; NFSv3 inventory was empty at inspection. Recheck immediately before NAS shutdown.
- Legacy Swarm and `onprem-prod` NFS shares still exist. Their existence does not prove active clients, but they must not be removed during maintenance.
- Pool is a **single disk**, not redundant. Last reported scrub finished with zero errors.
- No configured Proxmox backup jobs, local VM backups, or retained vzdump task entries were returned.
- No TrueNAS periodic snapshot tasks or replication tasks were returned. This does not establish whether manual snapshots or external backups exist.
- Original BIND9 address .50 did not answer a UDP DNS query; .92 did. VM cloud-init still lists .50. Avoid relying on that obsolete/unreachable DNS address during recovery; do not change DNS as part of this shutdown without a separate plan.

### Existing issues, not caused by preparation

- ArgoCD ApplicationSet controller is in CrashLoopBackOff; no ApplicationSet CRD is installed. No repair attempted.
- ArgoCD CoreDNS Application is Healthy but OutOfSync, with last operation Failed. No sync forced.
- TrueNAS warns the REST API is deprecated. Do not upgrade TrueNAS during this maintenance; CSI currently relies on REST.

## Pre-shutdown checklist (recorded during preparation; unresolved items remain relevant)

- [ ] Identify .2/.3/.4/.231 and physically match devices/cables/power supplies.
- [ ] Confirm whether fluiddpi and the 3D printer are included; recheck printer status and temperatures before shutting that controller down.
- [ ] Confirm the scope of other VLANs (this laptop is on 10.8.20.0/24).
- [ ] Establish a safe TrueNAS shutdown path via GUI/admin or authorized API; do not test by calling shutdown.
- [ ] Confirm current independent backups of important NFS application data, or explicitly accept the gap. The k3s backup does not cover that data.
- [ ] Establish local console/power-button access and a way to power Proxmox and TrueNAS back on. Wake-on-LAN/auto-power-on have not been verified.
- [ ] Keep the maintenance laptop awake and the WLAN/network path alive until servers are down.
- [ ] Obtain explicit authorization to begin the outage.

## Shutdown procedure (reference; actual execution recorded below)

The commands below are operational steps for the authorized outage, **not** preparation commands. Refresh inventories/replica counts if the outage occurs later. Never hard-stop guests automatically on a timeout.

1. Confirm backups, printer status and all final gates. Keep storage and network running.
2. Pause GitOps reconciliation before scaling any workloads. Stop the Application controller and ApplicationSet controller, retaining original replica counts (both currently 1). Do not merely disable child Application auto-sync: parent App-of-Apps reconciliation could restore it.

   Using the access helper's `kubectl` subcommand, the intended operations are:

   ```text
   -n argocd scale statefulset/argocd-application-controller --replicas=0
   -n argocd scale deployment/argocd-applicationset-controller --replicas=0
   ```

   Wait for those controller pods to exit and ensure no sync is still running. Leave CSI, Kubernetes DNS and the API available while application volumes are released.
3. Stop Home Assistant first, then Mosquitto. Also stop nginx-test and cloudflared if stopping all user workloads. All four Deployments currently have one replica.

   ```text
   -n homeassistant scale deployment/homeassistant --replicas=0
   -n homeassistant wait --for=delete pod --all --timeout=180s
   -n mosquitto scale deployment/mosquitto --replicas=0
   -n mosquitto wait --for=delete pod --all --timeout=180s
   -n nginx-test scale deployment/nginx-test --replicas=0
   -n cloudflared scale deployment/cloudflared --replicas=0
   ```

   Inspect termination failures rather than force deleting pods. If taking application-consistent data backups/snapshots, do it now while storage is still available and applications are stopped. A same-pool snapshot is not an independent backup.
4. Verify worker NFS mounts for the application volumes have disappeared (`findmnt -t nfs,nfs4`). Check TrueNAS clients/open states again with `truenas-read.py nfs/get_nfs4_clients` and `nfs/get_nfs3_clients`. If mounts remain, investigate before proceeding; do not forcibly unmount them or stop NAS first.
5. Gracefully shut down workers from Proxmox, e.g. `qm shutdown 201 --timeout 300` and `qm shutdown 202 --timeout 300`. Verify `qm status 201` and `qm status 202` report stopped. A timeout is a stop-and-investigate condition; **do not use `qm stop` as an automatic fallback**.
6. Gracefully shut down control-plane VM 200 (`qm shutdown 200 --timeout 300`) and verify stopped. Kubernetes API access ending here is expected; Proxmox SSH remains available.
7. Shut down fluiddpi if in scope, only after rechecking that the printer is idle, heater targets are zero, and hot components are safely cooled. Use the OS shutdown, not an abrupt power cut. Verify the controller is halted before removing its power.
8. Verify all Proxmox guests are stopped and no tasks/backup jobs are active. Shut down the Proxmox host cleanly via its OS. Verify physical power state; loss of ping/SSH alone is not proof.
9. Confirm any other identified stateful systems/storage clients outside Proxmox have also been shut down cleanly. Recheck TrueNAS for active storage clients/jobs (client leases may linger; investigate active open states). With all clients stopped and a valid shutdown path established, use TrueNAS's clean shutdown function. Do not export/destroy pools or cut power to a running NAS. Verify physically that it is off.
10. Turn off gateway, switches, APs and finally UPS/rack supply only after servers/storage are confirmed off. Keep the controlling network path until the end.

Avoid `kubectl drain` for a full-cluster shutdown: it can reschedule applications and prolong NFS use. This procedure scales intended application controllers down instead. No cordon/drain has been performed.

## Restart sequence

1. Restore safe cabling, power/UPS, switches, gateway and WLAN. Verify management IP connectivity.
2. Start TrueNAS and wait for pool `nas-01` ONLINE and NFS available.
3. Start Proxmox **after** TrueNAS is ready. All three Kubernetes VMs have `onboot: 1`, with no explicit startup-order setting: expect them to start automatically. No boot settings were changed during preparation.
4. Verify control plane and both workers Ready, guest agents active, CSI healthy, and PVCs still Bound. Use IP-based maintenance access rather than relying on .50 DNS.
5. While GitOps is still paused, restore Mosquitto, then Home Assistant; nginx-test/cloudflared as required. Restore exact counts from `replicas-before.json` rather than guessing if anything changed after preparation. Check MQTT persistence, Home Assistant database/logs and storage access.
6. Restore the ArgoCD Application controller and ApplicationSet controller to their recorded replica counts. Review pending Git changes before allowing reconciliation; do not blindly force-sync. The ApplicationSet controller may return to its pre-existing crash loop.
7. Check DNS (.92), Traefik (.90), MQTT (.91), Home Assistant, Cloudflare tunnel and ArgoCD. Compare with saved pre-maintenance state. Start fluiddpi/printer only when cabling is safe.
8. Keep recovery material until successful verification. The local API forward can then be stopped using its verified PID; do not kill an unrelated reused PID.

## Execution record — 2026-10-31

User explicitly authorized shutdown after receiving the preparation report, including its outstanding backup/access limitations.

- 13:00 CET: ArgoCD Application controller and ApplicationSet controller scaled to 0; pods gone. Home Assistant, Mosquitto, nginx-test and cloudflared scaled to 0, and their pods terminated. No PVC/PV/Application was deleted; no force-delete, drain, or hard VM stop used.
- Both worker NFS mounts were confirmed absent. TrueNAS retained only old delegation records for worker .71 (no open/lock states). NAS was kept running through guest shutdown; no forced unmount or client revocation was used.
- 13:05 CET: Proxmox confirmed VMs 201 and 202 `stopped` after graceful `qm shutdown`.
- 13:07 CET: Proxmox confirmed VM 200 `stopped`; all guests, including template 9000, were stopped.
- 13:07 CET: fluiddpi rechecked: print complete, heater targets 0, extruder about 17°C and bed about 21°C. `sudo systemctl poweroff` returned 0.
- 13:08 CET: Proxmox had no active tasks; `systemctl poweroff` returned 0.
- 13:08 CET: TrueNAS had no running/waiting jobs and no NFSv3 clients. Its remaining delegation records belonged to the already-stopped worker. TrueNAS accepted `POST /api/v2.0/system/shutdown` with JSON `{"reason":"User-requested network rack maintenance"}`, HTTP 200, job ID 518780. Earlier requests were rejected with HTTP 400 because this version requires `reason` and does not accept a top-level `delay`; those validation failures did not initiate shutdown.
- 13:09 CET: All tested management/storage ports of .19, .40, .70, .71, .72 and .100 were unreachable over WLAN. This corroborates shutdown but is **not physical power-state verification**.
- **Still reachable/not shut down:** .1, .2, .3, .4 and .231 on SSH. No valid administrative login was established for them; .3/.4/.231 identities/host keys remain unresolved. Do not interpret this record as confirmation that the entire rack or every VLAN is off.

Execution evidence is stored privately in `shutdown-execution.log`, `proxmox-guests-final.json`, `workloads-at-shutdown.json`, `argocd-at-shutdown.json`, and `shutdown-final-verification.json` beside the preparation backups.

### Essential restart reminder

Start network, then **TrueNAS**, wait for NFS/pool readiness, then start **Proxmox** (VMs have automatic boot enabled). ArgoCD controllers and the four user Deployments were deliberately left at **0 replicas** and must be restored using `replicas-before.json` / `workloads-at-shutdown.json` after storage and cluster health checks. The Application controller is a StatefulSet; the ApplicationSet controller is a Deployment. Kubernetes merely becoming Ready will not restart these scaled-down applications.

## Recovery and repair record — 2026-10-31

- The nodes, NAS/NFS and existing infrastructure returned healthy after power-on, but applications and ArgoCD controllers remained at 0 replicas from the deliberate shutdown. This was persisted desired state, not a scheduler/storage failure.
- Restored Mosquitto, Home Assistant, nginx-test and cloudflared to their recorded one replica; every rollout completed. Restored both ArgoCD controllers to one replica.
- The pre-existing ApplicationSet controller failure was independently confirmed in fresh logs: `failed to get restmapping: no matches for kind "ApplicationSet" in version "argoproj.io/v1alpha1"`. The `applicationsets.argoproj.io` CRD was absent.
- Fetched only `manifests/crds/applicationset-crd.yaml` from official ArgoCD tag `v3.4.1`, matching the installed controller. Validated its identity and server-side dry run, then installed it with server-side apply, without force-conflicts. Waited for Established, restarted the ApplicationSet controller and verified readiness. No ArgoCD version change was made.
- The CRD file is about 1.38 MB, so client-side apply's last-applied annotation is unsuitable. Bootstrap documentation now uses server-side apply and checks all three ArgoCD CRDs. Historical cause of the missing CRD is not proven; the size limit is a bootstrap risk, not a confirmed reconstruction of the original incident.
- Verification: all 29 pods Running/Ready; ApplicationSet controller has zero restarts after repair. Home Assistant and ArgoCD HTTPS endpoints return 200 with certificate verification. MQTT CONNECT receives successful CONNACK. Cloudflared logs show four registered tunnel connections.
- Separate outstanding issues: CoreDNS Application remains Healthy but OutOfSync, with existing sync error `Service "coredns" is invalid: spec.ports: Required value`; actual DNS pods run. Home Assistant logs contain integration-level errors for xtend_tuya, Ring, Roborock and some Shelly devices. These are not pod startup failures and were not modified as part of this repair.
- Evidence: `restart-execution.log`, `applicationset-before-fix.log`, `pods-after-recovery.json`, and application log tails in the private maintenance directory. fluiddpi intentionally excluded per user request.

## Subsequent DNS and GitOps repair — 2026-10-31

The remaining client access problem was reproduced as system DNS timeouts: Tailscale's stale server-subnet route and `~beary.cloud` DNS routing intercepted the maintenance laptop's normal traffic. The Susi WLAN profile now has a scoped local route/policy rule and more-specific private DNS routing, without disabling Tailscale. Normal HTTPS to both Home Assistant names now returns 200; WebSocket upgrade returns 101 and Home Assistant's `auth_required`. The public Cloudflare path also returns 200. This does not claim to alter routing on other client devices or verify a user's login.

- CoreDNS Helm zones now explicitly expose TCP as well as UDP 53, resolving its Service patch/sync failure.
- Migrated the three load-balancer annotations to `metallb.io/loadBalancerIPs`.
- Added a GitOps-managed K3s `coredns-custom` ConfigMap for private-zone forwarding instead of modifying the generated Corefile.
- Applied the tagged Ansible DNS repair to all nodes: independent public bootstrap upstreams, site-only link routing to .92, obsolete .20/.50 resolver paths removed from effective runtime configuration. Cloud-init DNS seeds on Proxmox and Terraform provisioning defaults now use .92. No VM restart was required.
- Fixed the Sealed Secrets chart repository's HTTP 404 by changing `bitnami-labs.github.io` to the active `bitnami.github.io` endpoint, keeping chart version 2.18.5/controller 0.36.6 and existing keys unchanged.
- GitOps configuration fixes committed/pushed as `dab9431` and `99c706a`. Verification: **all 17 ArgoCD Applications Synced/Healthy; all 29 pods Ready; all three nodes Ready without resource-pressure conditions**. Private and public DNS inside Home Assistant and on every node were checked, plus LAN DNS over both UDP/TCP.
- Historical warning events from shutdown/startup were retained, not deleted to hide failures. Home Assistant's separate integration-level errors are not Kubernetes failures and were not suppressed or bypassed.

See `docs/dns.md` for the current architecture and laptop-specific troubleshooting.
