# Homeserver To Homeserver2 Cluster Migration Plan

Date created: 2026-05-09
Owner: Omer
Goal: retire `homeserver`, rebuild the k3s cluster cleanly on `homeserver2`, and cut services over with minimal data loss and rollback risk.

---

## Principles

- Do not add `homeserver2` as a worker to the current cluster.
- Build a fresh single-node k3s cluster on `homeserver2`.
- Treat app data migration as the critical path.
- Keep `homeserver` intact until `homeserver2` is validated end-to-end.
- Cut over DNS/public routes only near the end.

---

## Target Architecture

### Runtime
- Single-node k3s cluster on `homeserver2`
- `homeserver2` remains the only control-plane node for now
- `homeserver` is retired after validation

### Storage
- `sda` (`447.1G` SSD): Ubuntu + k3s + system
- `nvme0n1p1` (`/data`, `238.5G` ext4): app data, configs, and fast local storage
- Future: move the `1TB` disk from `homeserver` into `homeserver2` for bulk storage/media

### Network
- LAN/private access preserved
- Cloudflare Tunnel routes cut over only after app validation
- AdGuard LAN DNS role moved carefully because it is production-critical

---

## Stage 0: Freeze And Inventory

Objective: stop drift and capture exactly what exists on `homeserver`.

Tasks:
- Freeze config changes on the current cluster during migration.
- Export a full inventory of namespaces, workloads, PVCs, PVs, ingresses, secrets strategy, and storage classes.
- Identify which apps are stateless vs stateful.
- Identify all manifests and host paths pinned to `homeserver`.
- Record current IPs, DNS rewrites, tunnel routes, and ingress hostnames.

Validation:
- A migration inventory exists and includes every stateful app and every host-local storage dependency.

---

## Stage 1: Backup And Rollback Preparation

Objective: make rollback possible before rebuilding anything.

Tasks:
- Take fresh backups of all important app data on `homeserver`.
- Export Kubernetes manifests for reference where useful.
- Confirm `restic` backup health and verify where cluster/app backups will be stored during migration.
- Capture app-specific recovery details:
  - `Vaultwarden`
  - `Home Assistant`
  - `Syncthing`
  - `Jellyfin`
  - `qBittorrent`
  - `Sonarr`
  - `Radarr`
  - `Bazarr`
  - `Prowlarr`
  - `Seerr`
  - `Uptime Kuma`
  - `Gotify`
- Define rollback rule: if `homeserver2` validation fails, traffic stays on `homeserver`.

Validation:
- Fresh backups exist and at least one restore path is documented for the highest-value apps.

---

## Stage 2: Prepare Homeserver2 Host Layout

Objective: make `homeserver2` ready to host the new cluster cleanly.

Tasks:
- Keep the current Ubuntu install on `homeserver2`.
- Confirm static/reserved LAN IP choice for `homeserver2`.
- Finalize host storage layout under `/data`.
- Create intended directories for app data and future media storage.
- Install baseline host packages needed for operations.
- Install and validate Tailscale/SSH/admin access if not already complete.
- Apply any host-level DNS resolver settings required for k3s image pulls.

Suggested layout:
- `/data/apps`
- `/data/media`
- `/data/backups`
- `/data/tmp`

Validation:
- `homeserver2` has stable remote access, correct host storage layout, and enough free space for the rebuilt cluster.

---

## Stage 3: Fresh k3s Bootstrap On Homeserver2

Objective: create the new clean cluster without touching production traffic yet.

Tasks:
- Install k3s fresh on `homeserver2` as a single server.
- Recreate cluster namespaces:
  - `infra`
  - `dns`
  - `apps`
  - `obs`
- Verify Traefik is healthy.
- Configure kubeconfig access from `omerPC`.
- Reapply any required host-specific k3s resolver overrides.

Validation:
- `kubectl get nodes` shows `homeserver2` as `Ready`.
- Core namespaces exist.
- Traefik is healthy.

---

## Stage 4: Adapt GitOps Manifests For Homeserver2

Objective: remove old node assumptions before deploying apps.

Tasks:
- Search the repo for:
  - `homeserver`
  - old host IPs
  - local PV paths
  - node affinity / node selectors
- Update manifests that assume `homeserver` specifically.
- Adjust local PV definitions to match the new storage layout on `homeserver2`.
- Decide which data should live on `/data` vs future bulk storage.
- Document any app that should remain deferred until the `1TB` disk is installed.

Known high-risk area:
- `homelab-repo/gitops/apps/jellyfin/pv-media-local.yaml` is pinned to `homeserver` and will need changes.

Validation:
- Repo no longer contains unintended scheduling/storage references to the retired node for the apps being migrated now.

### Current Repo Findings (Validated 2026-05-15)

- Hard blocker: `homelab-repo/gitops/apps/jellyfin/pv-media-local.yaml` is pinned to node `homeserver` and local path `/srv/media/jellyfin`.
- Media-path dependency: `tdarr` mounts the same Jellyfin media PVC at `/srv/media/jellyfin`.
- Media-stack dependency: `qBittorrent`, `Sonarr`, `Radarr`, `Bazarr`, `Prowlarr`, `Lidarr`, `Overseerr`, and `Tdarr` all depend directly or indirectly on `jellyfin-media-pvc`.
- Host-specific VPN hostname: `homelab-repo/gitops/apps/vaultwarden/ingress.yaml` still references `homeserver.tail73dbc9.ts.net`.
- Old cluster naming remains in Terraform defaults/examples:
  - `homelab-repo/terraform/variables.tf`
  - `homelab-repo/terraform/env/prod/terraform.tfvars.example`
- Old LAN IP `192.168.1.234` still appears in docs/runbooks, especially app README guidance for DNS rewrites.

### Required Repo Changes Before Cutover

1. Decide the new media root on `homeserver2`.
   - Decision made: use `/data/media/jellyfin` on `homeserver2` for the current migration.
2. Update `homelab-repo/gitops/apps/jellyfin/pv-media-local.yaml`.
   - Replace node affinity value `homeserver` with `homeserver2`.
   - Replace local path `/srv/media/jellyfin` with `/data/media/jellyfin`.
3. Keep the `jellyfin-media-pvc` contract stable for dependent apps.
   - Do not rename the PV or PVC unless every dependent manifest is updated together.
4. Update the Vaultwarden Tailscale ingress host after the new Serve/Funnel hostname exists on `homeserver2`.
5. Decide whether Terraform cluster naming should remain historical (`homeserver-k3s`) or be renamed now.
   - Renaming is cleaner but touches kubeconfig paths and bootstrap workflow.
   - Keeping the old logical name reduces migration churn.
6. Sweep docs and runbooks for `192.168.1.234` after the final `homeserver2` service IP is chosen.
   - Decision made: `homeserver2` stays on `192.168.1.101`.

### Practical Recommendation

- Migrate infra and smaller stateful apps first.
- Defer the media stack until the storage path on `homeserver2` is final.
- Do not change cluster name, app DNS names, and storage layout all in the same cutover if avoidable.

---

## Stage 5: Bring Up Core Infrastructure First

Objective: rebuild the base cluster services before restoring user apps.

Tasks:
- Deploy ArgoCD
- Deploy cloudflared
- Deploy AdGuard
- Deploy observability baseline as needed
- Validate private ingress first
- Keep public routes and LAN DNS cutover controlled and intentional

Recommended order:
1. ArgoCD
2. cloudflared
3. AdGuard
4. monitoring stack

Validation:
- Core infra apps are healthy on `homeserver2`.
- Private access works before public/LAN cutover is changed.

---

## Stage 6: Migrate Low-Risk Stateful Apps

Objective: restore simpler services before the heavy media stack.

Tasks:
- Migrate and validate:
  - `Gotify`
  - `Uptime Kuma`
  - `Vaultwarden`
  - `Syncthing`
  - `Home Assistant`
- Restore data one app at a time.
- Validate app login, data integrity, and ingress reachability after each restore.

Validation:
- Each migrated app is working on `homeserver2` with restored data and no dependency on `homeserver`.

---

## Stage 7: Migrate Media Stack

Objective: move the largest and most path-sensitive workloads last.

Tasks:
- Migrate:
  - `Jellyfin`
  - `qBittorrent`
  - `Sonarr`
  - `Radarr`
  - `Bazarr`
  - `Prowlarr`
  - `Seerr`
- Reconcile library/download paths on `homeserver2`.
- Decide whether media remains temporarily on the old disk, on `/data`, or waits for the `1TB` disk move.
- Validate path mappings, permissions, and app integrations.

Important note:
- If the `1TB` disk from `homeserver` is not yet moved, avoid unnecessary path churn. It may be better to defer final media layout until that disk is installed in `homeserver2`.

Validation:
- Media apps function correctly, and all path mappings resolve on `homeserver2`.

---

## Stage 8: Cutover

Objective: move real traffic from `homeserver` to `homeserver2`.

Tasks:
- Update Cloudflare Tunnel targets if needed.
- Update AdGuard DNS rewrites/internal hostnames if needed.
- Move LAN DNS role carefully if AdGuard endpoint/IP changes.
- Validate public routes, private routes, and Tailscale paths.
- Confirm no user-facing traffic still depends on `homeserver`.

Validation:
- Required services resolve and load via their intended paths from LAN, Tailscale, and public routes where applicable.

### Cutover Notes For This Environment

- The highest-risk cutover is AdGuard because router DHCP currently points clients at the old DNS host IP path.
- If `homeserver2` takes over the same LAN IP, cutover is simpler but requires careful host shutdown/swap coordination.
- If `homeserver2` uses a new LAN IP, every `*.home.arpa` rewrite in AdGuard must be updated, and the router DNS setting must be changed to the new address.
- Cloudflare Tunnel cutover is lower risk than DNS cutover because traffic can remain private until internal validation is complete.

## First Execution Slice

If the goal is to start now with the least risk, use this order:

1. Finalize `homeserver2` LAN IP strategy.
   - Chosen: keep `homeserver2` on `192.168.1.101`.
2. Finalize storage layout on `homeserver2`.
   - Chosen media root: `/data/media/jellyfin`.
3. Bootstrap fresh k3s on `homeserver2`.
4. Update repo references that are definitely wrong for the new host:
   - Jellyfin PV node/path
   - Vaultwarden Tailscale hostname
   - docs that still instruct DNS rewrites to `192.168.1.234`
5. Bring up ArgoCD, Traefik, cloudflared, and AdGuard on `homeserver2`.
6. Restore and validate `Gotify`, `Uptime Kuma`, `Vaultwarden`, `Syncthing`, and `Home Assistant`.
7. Migrate the media stack only after the final disk/path decision is in place.

---

## Stage 9: Decommission Homeserver

Objective: retire the old machine only after the new environment is stable.

Tasks:
- Leave `homeserver` powered but idle for a short observation period if possible.
- Confirm backups now cover `homeserver2`.
- Shut down k3s on `homeserver`.
- Remove stale kubeconfig, DNS, and route references to `homeserver`.
- Repurpose or physically move the `1TB` disk into `homeserver2` when ready.

Validation:
- No production homelab service depends on `homeserver`.

---

## Recommended Migration Order By Risk

1. Inventory and backup
2. Prepare `homeserver2`
3. Fresh k3s bootstrap
4. Fix manifests pinned to `homeserver`
5. Infra services
6. Small stateful apps
7. Media stack
8. Traffic cutover
9. Retire `homeserver`

---

## Open Decisions

- Exact `/data` directory structure for app data
- Whether AdGuard keeps the same LAN-serving IP during cutover
- Which apps to defer until the `1TB` disk is physically moved
- Whether the media stack should be restored twice:
  - once temporarily on current storage
  - again later onto the moved `1TB` disk

---

## Immediate Next Steps

1. Build a full stateful app and storage inventory from the current cluster.
2. Decide the final directory layout on `homeserver2` under `/data`.
3. Identify every manifest in `homelab-repo` that is pinned to `homeserver`.
4. Create a migration checklist for each stateful app with backup source, restore path, and validation method.
