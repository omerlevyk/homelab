# Homelab Jobs Tracker

Date created: 2026-02-28
Owner: Omer
Status rule: check the box only when the validation line under that task is true.

---

## Focus Board (Checklist-First)

### Now (active work)
- [ ] Build out `Home Assistant` integrations and first automations.
Validation: mobile app is connected, key homelab integrations are visible in HA, and at least 3 useful automations are working end-to-end.

- [ ] Complete backup restore validation for `restic`.
Validation: one clean restore test completes and restored data is verified.

- [ ] Record v1 storage decision (local-path now, TrueNAS later) in docs.
Validation: storage decision and migration note exist in repo docs.

- [ ] Finalize backup retention + target documentation.
Validation: policy and target are documented and match running config.

- [ ] Make app access private-by-default.
Validation: app UIs are not reachable via public internet domains.

- [ ] Enforce Tailscale-only remote access.
Validation: access from outside LAN works only when client is connected to Tailscale.

### Next
- [ ] Select secrets strategy (`SOPS` or `Sealed Secrets`).
Validation: no plaintext credentials in git history.

- [ ] Add `Home Assistant` integrations for homelab visibility.
Validation: `Jellyfin`, `AdGuard Home`, `Uptime Kuma`, Android TV, and the HA mobile app are connected or intentionally skipped with a reason documented.

- [ ] Build first `Home Assistant` dashboard for media + homelab status.
Validation: one dashboard shows service health, media status, and key device/entity controls in a useful layout.

- [ ] Create first `Home Assistant` automations.
Validation: at least 3 automations run successfully in real use.

- [ ] Restrict admin surfaces to private access only.
Validation: ArgoCD/Traefik/AdGuard/admin endpoints are not publicly exposed.

- [ ] Add baseline RBAC and pod security constraints.
Validation: service accounts are namespace-scoped and no unnecessary privileged pods.

- [ ] Deploy minimum observability stack: Prometheus + Grafana + Uptime Kuma.
Validation: Prometheus/Grafana dashboards load, and Uptime Kuma endpoint checks run on schedule.

- [ ] Add alerts for DNS failure, ingress failure, and low disk.
Validation: test alert fires and is received on chosen channel.

### Runbooks
- [ ] DNS down runbook
- [ ] Disk full runbook
- [ ] Tunnel down runbook
- [ ] Failed app rollout runbook
Validation: runbooks exist and each was tested once in dry run.

### Later
- [ ] Provision dedicated TrueNAS VM/hardware.
Validation: TrueNAS management access works and storage pool is healthy.

- [ ] Export storage to k3s (NFS/iSCSI) and test provisioning.
Validation: test PVC binds and survives restart/reschedule.

- [ ] Migrate stateful workloads to TrueNAS-backed volumes.
Validation: app data intact post-migration and rollback snapshot available.

---

## Milestones
- [x] M1: k3s ready + AdGuard serving home DNS
- [x] M2: Cloudflare Tunnel live + first app public
- [ ] M3: Backups tested + runbooks in place
- [ ] M4: TrueNAS migration complete (optional post-v1)

---

## Current Baseline (Context)
- [x] Temporary Docker Traefik test removed from homeserver.
Validation: `docker ps` shows no active Traefik container and ports `80/443` are free for k3s ingress.

- [x] k3s single-node cluster installed and healthy.
Validation: `kubectl get nodes` returns one `Ready` node.

- [x] Namespaces created: `infra`, `dns`, `apps`, `obs`.
Validation: `kubectl get ns` includes all 4 namespaces.

- [x] k3s Traefik is the only active ingress controller.
Validation: one active Traefik deployment/service in cluster and no external Docker Traefik.

- [x] AdGuard deployed with persistent storage and LAN DNS active.
Validation: pod `Running`, PVC `Bound`, LAN clients resolve/block as configured.

- [x] Cloudflare Tunnel deployed and healthy.
Validation: tunnel connected and routes mapped correctly.

- [x] First app rollout complete: Jellyfin via GitOps.
Validation: ArgoCD app healthy and service reachable through intended path.

- [x] Internal DNS hostnames on `*.home.arpa` configured.
Validation: LAN and Tailscale clients resolve internal hostnames and reach apps.

---

## Change Log (Condensed)

### 2026-03-01
- Phase 0 baseline audited: SSH, hostname/time sync, stable LAN IP validated.
- Tailscale remote admin path validated (`homeserver@100.91.188.74`).
- v1 scope locked: single-node k3s, Traefik, AdGuard, cloudflared, one app.
- Backups: `restic` selected, repo initialized over SFTP, retention set (`7 daily / 4 weekly / 3 monthly`), `restic check` passed.
- Restore test blocked by permission/context issues; Phase 2 remained in progress.
- AdGuard resources and PVC in place; DNS serving pending wizard/listener setup.

### 2026-03-02
- AdGuard wizard completed; DNS + blocking validation passed.
- Router DHCP DNS updated to AdGuard (`192.168.1.234`).
- Cloudflared deployed via ArgoCD; public test route validated (`whoami.omerlevy03.com` HTTP 200).
- Test workload cleaned up and router port forwarding confirmed disabled.
- WAN checks against public IP showed no reachable service ports.
- Ops UI plan noted: Headlamp early, Dashy optional; full metrics later.
- Phase 5 app decision: Jellyfin.

### 2026-03-05
- Added Jellyfin GitOps manifests (deployment, service, PVCs, resource limits).
- Added cluster sync entry and Cloudflare route example.
- Added ingress for Jellyfin, HomePage, and ArgoCD.
- Updated tunnel route model to point hostnames to Traefik service.
- Created ArgoCD root app `infra/prod-root`.
- Removed overlapping legacy ArgoCD app ownership.
- Fixed ArgoCD public access/redirect loop via tunnel route + `server.insecure=true`.
- Added AdGuard ingress/domain route and moved HomePage shortcut to domain-based links.
- Confirmed domain access for ArgoCD, HomePage, Jellyfin, and AdGuard.

### 2026-03-06
- Added internal ingress hosts:
  - `homepage.home.arpa`
  - `jellyfin.home.arpa`
  - `argocd.home.arpa`
  - `adguard.home.arpa`
  - `traefik.home.arpa`
- Added AdGuard DNS rewrites to `192.168.1.234`.
- Split AdGuard services to resolve DNS/web exposure conflict:
  - `Service/adguard` for DNS (`53`)
  - `Service/adguard-web` for web (`80`, ClusterIP)
- Validation:
  - Public: `homepage.omerlevy03.com` (`200`), `jellyfin.omerlevy03.com` (`302`)
  - Public admin routes blocked (`530`)
  - Private internal endpoints reachable over LAN/Tailscale.

### 2026-03-07
- Applications roadmap reviewed and prioritized.

### 2026-03-13
- Fixed private app access over Tailscale by using the correct DNS/routing path for `*.home.arpa`.
- Deployed `Gotify` via GitOps with private-only access on `gotify.home.arpa`.
- Deployed `iGotify` notification assistant via GitOps and completed local-instance wiring for iPhone push notifications.
- Deployed `Uptime Kuma` via GitOps with private-only access on `uptime-kuma.home.arpa`.
- Connected `Uptime Kuma` notifications to `Gotify`.
- Added monitoring coverage for selected apps and cleaned up duplicate HomePage cards for `Gotify`/`iGotify`.

### 2026-03-14
- Added `Vaultwarden` GitOps manifests with private-only ingress on `vaultwarden.home.arpa`.
- Added a follow-up note to create the matching AdGuard DNS rewrite to `192.168.1.234`.
- Kept Vaultwarden off public Cloudflare routes and disabled self-signups/invitations by default.

### 2026-03-17
- Enabled private HTTPS access to `Vaultwarden` through Tailscale Serve on `https://homeserver.tail73dbc9.ts.net`.
- Added a matching Vaultwarden ingress host for the `ts.net` hostname and updated the HomePage card to use the Tailscale HTTPS URL.
- Completed first-user/client setup with the web vault, browser extension, and mobile app.
- Re-disabled `SIGNUPS_ALLOWED` after bootstrap so the instance returned to closed registration.

### 2026-04-04
- Deployed `Syncthing` via GitOps with private-only access on `syncthing.home.arpa`.
- Completed device pairing and folder sync setup between the homeserver, Linux PC, and iPhone.
- Added `Syncthing` monitoring in `Uptime Kuma`.
- Removed the duplicate HomePage entry and kept a single `Syncthing` card under `Infrastructure`.

### 2026-04-18
- Added `Home Assistant` GitOps manifests under `homelab-repo/gitops/apps/home-assistant`.
- Wired `Home Assistant` into `homelab-repo/gitops/clusters/prod/kustomization.yaml`.
- Added private-only ingress on `home-assistant.home.arpa`.
- Added Homepage annotations for a single `Home Assistant` card.
- Defined the next `Home Assistant` task as integrations + dashboard + first automations.

### 2026-04-28
- Enabled `Seerr` inside Jellyfin for in-app request/discovery workflow on supported Jellyfin UI paths/clients.
- Kept `Seerr` as the backing request service for approvals and media acquisition flow.

### 2026-06-17
- Renamed the OS hostname on the active server to `homeserver` while keeping the Linux user as `homeserver2`.
- Fixed local `kubectl` access on the server by restoring a working kubeconfig under `/home/homeserver2/.kube/config`.
- Diagnosed the hostname-rename fallout: bound PVs still had immutable node affinity pinned to `homeserver2`, which left most stateful apps `Pending`.
- Restored scheduling safely by making `k3s` register the node again as `homeserver2` through `/etc/systemd/system/k3s.service.env`.
- Deleted the stale `homeserver` node object after the recovery so the cluster returned to a single active node.
- Repaired host DNS handling so `/etc/resolv.conf` uses `systemd-resolved` again.
- Diagnosed the public app outage as a DNS recursion/upstream problem:
  - host link DNS preferred a broken IPv6 resolver
  - `CoreDNS` timed out forwarding through `AdGuard`
  - `cloudflared` failed SRV and API lookups
- Changed the host resolver on `eno1` to IPv4-only upstreams (`1.1.1.1`, `1.0.0.1`).
- Updated `AdGuard` upstream DNS away from the broken/self-referential path and restarted `AdGuard`, `CoreDNS`, and `cloudflared`.
- Validation:
  - `cloudflared` connectivity prechecks passed
  - internal `Homepage` recovered on `homepage.home.arpa`
  - public `Homepage` recovered on `https://homepage.omerlevy03.com`
- Current naming reality after recovery:
  - OS hostname = `homeserver`
  - Linux user = `homeserver2`
  - k3s node name = `homeserver2`
- Next:
  - make the host DNS settings persistent so they survive reboot
  - revert repo changes that incorrectly assumed the live k3s node name changed to `homeserver`
  - fix remaining app-level readiness issues for `Home Assistant`, `iGotify`, `Syncthing`, `Uptime Kuma`, and `Vaultwarden`

---

## Applications Roadmap (Checklist)
Review date: 2026-03-07
Legend:
- `Must` = strong fit now
- `Optional` = useful but not required now
- `Later` = defer until stability/capacity improves

### Home / Productivity
- [x] HomePage (`Must`)
- [ ] Home Assistant (`Optional`)
Validation: ArgoCD app is healthy, PVC is `Bound`, `home-assistant.home.arpa` is reachable on LAN/Tailscale, Homepage shows one `Home Assistant` card, and first core integrations are connected.
- [x] Syncthing (`Must`)
- [x] Vaultwarden (`Must`)

### Media Stack
- [x] Jellyfin (`Must`)
- [x] Seerr (`Optional`)
- [x] qBittorrent (`Optional`)
- [x] Sonarr (`Optional`)
- [x] Radarr (`Optional`)
- [ ] Lidarr (`Later`)
- [x] Bazarr (`Later`)
- [ ] Roon (`Optional`)

### Monitoring / Operations
- [x] Uptime Kuma (`Must`)
- [ ] Prometheus (`Must`)
- [ ] Grafana (`Must`)
- [x] Gotify (`Must`)

### Dev / Platform
- [x] ArgoCD (`Must`)
- [ ] Forgejo or Gitea (`Optional`)

### Storage
- [ ] Nextcloud (`Optional`)
- [ ] TrueNAS (`Later`)

Recommended rollout order (next 5):
1. Home Assistant
2. Prometheus
3. Grafana

### Home Assistant Initial Scope
- [x] Jellyfin integration
- [ ] Home Assistant mobile app
- [ ] Android TV integration
- [ ] AdGuard Home integration
- [ ] Uptime Kuma integration or HA-facing health sensors
- [ ] Router/network integration if supported

Validation: the selected integrations are connected and producing useful entities in Home Assistant.

### Home Assistant First Automations
- [ ] Presence-aware homelab alerts
- [ ] Android TV / media automation
- [ ] Service outage notification flow

Validation: each automation is tested once in real use.

---

## Notes
- Keep this file as the single source of truth for execution status.
- Update after every meaningful deploy, rollback, incident, or test.
- connect each new app to up-time kuma and gotify.
- with each git push write down a commit massage suggestion.
