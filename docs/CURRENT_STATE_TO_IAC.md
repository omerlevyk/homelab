# Current State To IaC Baseline

Date: 2026-03-02
Owner: Omer
Workstation: `omerPC` (control)
Cluster node: `homeserver` (`192.168.1.234`)

This file is the manual-as-built baseline before full Terraform + Helm + ArgoCD migration.

## 1) Operating Model (From Now On)
- IaC authoring/execution host: `omerPC`
- Runtime cluster: k3s on `homeserver`
- Source of truth target: GitHub repos
- Rule:
  - Host OS/network changes stay as host ops (or Ansible later).
  - Kubernetes resources move to Terraform/Helm first, then app-level GitOps via ArgoCD.

## 2) Completed Manual Work

### Phase 0 (Completed)
- Host baseline validated after upgrade/reboot.
- Tailscale installed and verified (`omerPC` -> `homeserver` over tailnet SSH).
- v1 scope locked:
  - k3s + Traefik + AdGuard + Cloudflare Tunnel + one app.

### Phase 1 (Completed)
- k3s installed on `homeserver`.
- Namespaces created: `infra`, `dns`, `apps`, `obs`.
- k3s Traefik confirmed as ingress controller.

### Phase 2 (In Progress)
- Restic selected and configured to backup over SFTP to `omerPC`.
- Repo initialized and snapshots/check/retention configured.
- Restore test is still not cleanly validated; phase remains open.

### Phase 3 (Completed)
- AdGuard deployed in `dns` namespace with PVC.
- AdGuard service exposed and reachable on LAN.
- Router DHCP DNS updated to `192.168.1.234`.
- DNS validation passed:
  - `google.com` resolves.
  - ad domains (`doubleclick.net`, `googleadservices.com`, `adservice.google.com`, `googlesyndication.com`) blocked.

## 3) Current Cluster DNS/AdGuard State
- Namespace: `dns`
- Workload: `Deployment/adguard`
- Storage: `PersistentVolumeClaim/adguard-pvc`
- Service: `Service/adguard` (`LoadBalancer` type; working on host IP path)
- Active LAN DNS endpoint: `192.168.1.234:53`
- AdGuard web UI endpoint: `http://192.168.1.234/`

## 4) Host-Level Changes Relevant To IaC Migration
- `homeserver` uses k3s.
- k3s resolver override was configured:
  - systemd override file sets `K3S_RESOLV_CONF=/run/systemd/resolve/resolv.conf`
  - path: `/etc/systemd/system/k3s.service.d/10-resolv.conf.conf`
- `/etc/resolv.conf` was switched to `/run/systemd/resolve/resolv.conf` to fix image pulls.
- Tailscale DNS auto-accept was disabled during troubleshooting (`--accept-dns=false`).

These are host settings, not k8s manifests. Keep them documented and intentional.

## 5) IaC Ownership Map

### Terraform (bootstrap/infra)
- Cluster namespaces (`infra`, `dns`, `apps`, `obs`)
- Helm releases:
  - ArgoCD
  - Cloudflared
  - AdGuard (or k8s manifests managed by Terraform provider, if no Helm chart selected)
- Optional: Cloudflare DNS/tunnel records (provider-based)

### ArgoCD (continuous sync)
- App workloads in `apps` namespace
- Optional infra app manifests after bootstrap (if desired split is "Terraform bootstrap, Argo sync ongoing")

## 6) Migration Sequence (Recommended)
1. Create Terraform root files in `infra-terraform/` and wire providers to `homeserver` kubeconfig/API.
2. Codify namespaces in Terraform and apply (no behavior change expected).
3. Codify AdGuard resources as Terraform-managed manifests or Helm release.
4. Import/adopt existing live resources where appropriate to avoid recreate surprises.
5. Install ArgoCD via Terraform Helm provider.
6. Create `homelab-gitops/` app-of-apps structure and move app manifests there.
7. Deploy Cloudflared via Terraform, then shift route definitions to GitOps/pipeline policy.

## 7) Open Decisions Before Full IaC Cutover
- AdGuard delivery model: Helm chart vs raw manifests.
- Service exposure long-term:
  - Keep current host-IP path, or
  - move to MetalLB for cleaner static service IP ownership.
- Secrets model: SOPS vs Sealed Secrets.
- Exact split boundary: what stays Terraform-managed long-term vs moved under ArgoCD.

## 8) Do Not Lose
- Current working DNS path (`192.168.1.234:53`) is production-critical.
- Avoid disruptive re-creates of:
  - `dns/adguard-pvc`
  - `dns/adguard` service identity
  - router DHCP DNS settings

