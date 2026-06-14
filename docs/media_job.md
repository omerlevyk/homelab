# Media Stack Build Checklist

Date created: 2026-03-09
Owner: Omer
Status rule: check the box only when the validation line under that task is true.

---

## Goal
Build a complete, private-by-default media stack on k3s with GitOps, extending the existing Jellyfin setup.

## Current State
- [x] Jellyfin is deployed in namespace `apps`.
- [x] Jellyfin media PV is planned to move to `/data/media/jellyfin` on `homeserver2`.
- [x] Media library currently contains ~24 GB of videos.
- [x] Cluster sync path includes `gitops/clusters/prod/kustomization.yaml`.

Validation: `kubectl -n apps get deploy jellyfin` is `Available`, and PVC/PV are `Bound`.

---

## Target Stack
Core:
- Jellyfin (already running)
- qBittorrent
- Sonarr
- Radarr
- Lidarr
- Bazarr
- Prowlarr (recommended indexer manager)
- Seerr (requests + approvals)
- Tdarr (media cleanup/transcode automation)

Optional later:
- Roon

---

## Phase 0: Storage + Layout Prerequisites
- [x] Define canonical media paths under `/data/media/jellyfin`.
Validation: paths are documented and used consistently across all app mounts.

Recommended layout:
- `/data/media/jellyfin/downloads/incomplete`
- `/data/media/jellyfin/downloads/complete`
- `/data/media/jellyfin/library/movies`
- `/data/media/jellyfin/library/tv`
- `/data/media/jellyfin/library/music`
- `/data/media/jellyfin/library/subtitles`

- [x] Create and permission all required directories on `homeserver2`.
Validation: container runtime UID/GID can read/write all paths.

- [x] Decide identity model for media containers (`PUID`/`PGID`/`umask`).
Validation: test file created by qBittorrent is writable by Sonarr/Radarr/Lidarr/Bazarr.

- [x] Keep one shared media PV approach for v1 (local-path on single node).
Validation: each media app mounts the same underlying media root with correct subpaths.

---

## Phase 1: GitOps Scaffolding
- [x] Create app directories:
  - `gitops/apps/qbittorrent`
  - `gitops/apps/prowlarr`
  - `gitops/apps/sonarr`
  - `gitops/apps/radarr`
  - `gitops/apps/lidarr`
  - `gitops/apps/bazarr`
Validation: each app folder has `kustomization.yaml`, `deploy.yaml`, `svc.yaml`, PVC/PV files as needed.

- [x] Add new media apps to `gitops/clusters/prod/kustomization.yaml`.
Validation: ArgoCD `prod-root` sync includes all media app resources.

- [x] Create secrets placeholders (no plaintext creds in repo).
Validation: all API keys/passwords come from Kubernetes Secrets, not inline env vars.

---

## Phase 2: qBittorrent (Downloader)
- [x] Deploy `qBittorrent` in namespace `apps` with persistent config storage.
Validation: pod is `Running`, config PVC is `Bound`, web UI reachable on private host.

- [x] Mount shared downloads path for completed/incomplete data.
Validation: files written to `/downloads/incomplete` move to `/downloads/complete`.

- [x] Configure categories and save paths for:
  - `tv`
  - `movies`
  - `music`
Validation: test torrents in each category land in expected paths.

- [x] Restrict qBittorrent UI to LAN/Tailscale only.
Validation: qBittorrent public domain does not resolve to active public route.

---

## Phase 3: Prowlarr (Indexer Management)
- [x] Deploy `Prowlarr` with persistent config.
Validation: pod is `Running`, config persists after restart.

- [x] Add indexers in Prowlarr and verify successful test responses.
Validation: at least one indexer per media type is healthy.

- [x] Integrate Prowlarr with Sonarr/Radarr/Lidarr.
Validation: apps receive synced indexers and test queries succeed.

---

## Phase 4: Sonarr + Radarr + Lidarr
- [x] Deploy `Sonarr` with config PVC and shared media/download mounts.
Validation: Sonarr imports completed TV downloads into `library/tv`.

- [x] Deploy `Radarr` with config PVC and shared media/download mounts.
Validation: Radarr imports completed movie downloads into `library/movies`.

- [ ] Deploy `Lidarr` with config PVC and shared media/download mounts.
Validation: Lidarr imports completed music downloads into `library/music`.

- [x] Configure qBittorrent download client in all *arr apps.
Validation: manual search + grab from each app starts torrent job in qBittorrent.

- [ ] Configure root folders and quality profiles in each app.
Validation: test import places files in correct root folders and naming format.

---

## Phase 5: Bazarr (Subtitles)
- [x] Deploy `Bazarr` with persistent config and read access to media libraries.
Validation: Bazarr can scan existing libraries from Sonarr/Radarr paths.

- [x] Integrate Bazarr with Sonarr and Radarr APIs.
Validation: Bazarr shows connected status for both apps.

- [x] Configure subtitle providers/languages.
Validation: subtitle job downloads at least one subtitle for a known title.

---

## Phase 6: Jellyfin Integration
- [x] Ensure Jellyfin libraries point to canonical `library/*` folders only.
Validation: Jellyfin scans content without duplicate/mixed path issues.

- [x] Enable scheduled library refresh and metadata refresh.
Validation: newly imported media appears in Jellyfin without manual filesystem fixes.

- [x] Confirm subtitle discovery in Jellyfin from Bazarr-managed files.
Validation: at least one test title shows playable external subtitle track.

---

## Phase 7: Seerr (Request Workflow)
- [x] Deploy `Seerr` with persistent config in namespace `apps`.
Validation: pod is `Running`, config PVC is `Bound`, UI reachable on private hostname.

- [x] Integrate Seerr with Jellyfin.
Validation: users/library sync works and media availability status is correct.

- [x] Expose `Seerr` request/discovery inside Jellyfin.
Validation: compatible Jellyfin web UI/client shows the `Seerr` integration path and at least one request/discovery action works from inside Jellyfin.

- [x] Integrate Seerr with Sonarr and Radarr.
Validation: approved TV requests create Sonarr items; approved movie requests create Radarr items.

- [x] Configure approval model and user permissions.
Validation: non-admin user can submit request; approval flow works as configured.

---

## Phase 8: Access + Security Hardening
- [x] Keep all media admin UIs private (LAN/Tailscale only).
Validation: no public Cloudflare routes for qBittorrent/Prowlarr/*arr/Bazarr admin UIs.

- [ ] Rotate default passwords and store credentials in secrets management flow.
Validation: no default admin creds remain.

- [ ] Add resource requests/limits for each media service.
Validation: all deployments specify CPU/memory requests and limits.

- [ ] Add backup coverage for media app config PVCs.
Validation: one backup + one restore test per critical config PVC succeeds.

---

## Phase 9: Operations + Runbooks
- [ ] Add HomePage entries for media services using internal hostnames.
Validation: all media links resolve and open on LAN/Tailscale.

- [ ] Add uptime checks for Jellyfin and key media APIs.
Validation: checks run on schedule and alert on simulated outage.

- [ ] Create media runbooks:
  - [ ] Download stuck
  - [ ] Import failed
  - [ ] Subtitle sync failed
  - [ ] Disk usage high
Validation: each runbook is tested once in dry run.

---

## Phase 10: Tdarr
- [x] Add `Tdarr` GitOps manifests with private-only access on `tdarr.home.arpa`.
Validation: `Tdarr` resources exist under `gitops/apps/tdarr`, are included in `gitops/clusters/prod/kustomization.yaml`, and expose only the internal hostname.

- [ ] Configure initial Tdarr library mappings and a safe first plugin stack.
Validation: at least one test library scans successfully and a non-destructive health check or cleanup rule runs on a small sample set.

---

## Suggested Build Order
1. Storage layout + permissions
2. qBittorrent
3. Prowlarr
4. Sonarr
5. Radarr
6. Lidarr
7. Bazarr
8. Jellyfin final integration
9. Seerr
10. Tdarr
11. Hardening + backups + runbooks

---

## Definition of Done (Media Stack v1)
- [x] qBittorrent, Prowlarr, Sonarr, Radarr, and Bazarr are running via GitOps in `apps` namespace. `Lidarr` is optional unless music is in scope.
- Scope note: security hardening, backups, and runbooks are tracked here but are currently deferred from the "media stack built" milestone.
- [ ] End-to-end flow works for TV + Movies (+ Music if enabled): search -> download -> import -> visible in Jellyfin.
- [ ] Seerr request flow works end-to-end: request from Seerr or supported Jellyfin integration -> approval (if enabled) -> Sonarr/Radarr -> download/import -> available in Jellyfin.
- [ ] Subtitle automation works for at least one TV and one Movie title.
- [ ] Admin surfaces are private-only (LAN/Tailscale), no unintended public exposure.
- [ ] Config backups and restore validation are complete.
