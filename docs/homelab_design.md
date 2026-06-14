# HomeLab Design: Cloudflare Domain + Home Ad Blocking (IaC: Terraform + Helm on k3s)

Date: 2026-02-28  
Goal: A HomeLab system with separate compute and storage roles: Ubuntu VM for k3s workloads and a dedicated TrueNAS VM for storage, with secure external access through Cloudflare Tunnel and network-wide ad blocking using a DNS sinkhole (AdGuard Home), fully managed as IaC (Terraform + Helm).

---

## 1) Goals and Requirements

### Goals
- **Network-wide ad blocking** (DNS level) without installing software on every device.
- **No open inbound internet ports** (Zero Trust).
- **Access to public services** (Nextcloud/Immich, etc.) through Cloudflare Tunnel.
- **Internal admin access** through Tailscale.
- **GitOps** (ArgoCD) for workload management.
- **Full IaC**: Terraform creates and manages Helm releases + resources (including Cloudflare if needed).

### Non-Functional Requirements
- DNS must be **stable** (if DNS goes down, the home network effectively goes down).
- Application persistence (PVC + ZFS snapshots).
- Security separation: Public / Internal / Admin.

---

## 2) High-Level Architecture Diagram

```text
Internet
  |
Cloudflare (DNS + Zero Trust)
  |
Cloudflare Tunnel (cloudflared)
  |
Hypervisor Host
  |-- VM 1: Ubuntu + k3s (compute)
  |     |-- Tailscale (Admin VPN)
  |     |-- Core
  |     |    - Traefik (Ingress)
  |     |    - cert-manager (optional, based on TLS strategy)
  |     |    - ArgoCD (GitOps)
  |     |    - Secrets: SOPS/Sealed-Secrets
  |     |
  |     |-- Network Services
  |     |    - AdGuard Home (DNS ad-block)
  |     |    - MetalLB (optional, for stable LAN IP)
  |     |
  |     |-- Apps
  |     |    - Nextcloud, Immich, Vaultwarden, MinIO (optional)
  |     |    - Jellyfin, Sonarr, Radarr, Navidrome
  |     |
  |     +-- Observability
  |          - Prometheus, Grafana, Loki (optional), Alertmanager (optional)
  |          - Uptime Kuma
  |
  +-- VM 2: TrueNAS (storage)
        - NFS/iSCSI datasets for k3s PVCs
        - Snapshots and replication/backup
```

---

## 3) Architectural Decisions (Key Decisions)

### 3.1 DNS Ad Blocking: AdGuard Home (Recommended)
- Runs as a DNS sinkhole with a convenient UI and good stability on k8s.
- Also provides local DNS records (internal names such as `grafana.home`).

### 3.2 Access Separation
- Public (internet): only through Cloudflare Tunnel for HTTP/HTTPS.
- Admin: only through Tailscale (`SSH`, `ArgoCD UI`, `Grafana internal`).
- LAN: DNS (AdGuard) available only to the home network.

### 3.3 DNS Stability (Critical)
Choose one option:

- Option A (recommended): `MetalLB + LoadBalancer Service`.
  - AdGuard gets a fixed LAN IP (for example `192.168.1.53`).
  - Router setting: `Primary DNS = 192.168.1.53`.
- Option B: `NodePort + server IP`.
  - Simpler, but less clean and more port-dependent.
  - Router setting: `DNS = server IP` (for example `192.168.1.10`) with port `53`.

Recommendation: for a cleaner long-term setup, choose MetalLB.

### 3.4 TLS Strategy (Important Decision)
If all public traffic goes through Cloudflare Tunnel, TLS often terminates at Cloudflare.

You can choose:
- `TLS terminated at Cloudflare` (simpler).
- `End-to-end TLS` (Cloudflare to origin with cert-manager) (more advanced).

### 3.5 TrueNAS Placement (Recommended)
- Run TrueNAS in a **separate VM** from the k3s VM.
- Keep roles split:
  - VM 1: compute/control plane (`k3s`, ingress, apps).
  - VM 2: storage (`TrueNAS`, datasets, snapshots, replication).
- Reason: better isolation for upgrades, incidents, and security boundaries.

---

## 4) Traffic Flows

### 4.1 Public Access to Services
`User on Internet -> Cloudflare DNS -> Cloudflare Tunnel -> Traefik Ingress -> Service/Pod`

Rule: no direct server exposure and no port forwarding.

### 4.2 Admin Access
`Admin device -> Tailscale -> SSH / k8s API / ArgoCD / Grafana`

Rule: admin endpoints are not exposed through Cloudflare.

### 4.3 Network-Wide DNS Ad Blocking
`LAN device -> Router DNS -> AdGuard Home -> Upstream DNS (Cloudflare/Quad9/Unbound)`

---

## 5) Namespaces and Boundaries

Recommended namespace structure:

- `infra`
  - ArgoCD, cert-manager, traefik, sealed-secrets/sops, metalLB, cloudflared
- `dns`
  - AdGuard Home
- `apps`
  - nextcloud, immich, vaultwarden, minio, jellyfin, *arr stack, navidrome
- `obs`
  - prometheus, grafana, loki, alertmanager, uptime-kuma

Benefits:
- Permission separation.
- Network policy separation (future).
- Better IaC organization.

---

## 6) Storage Design (TrueNAS + PVC)

### 6.1 Current State
- Recommended baseline: dedicated TrueNAS VM exports storage to k3s.
- Use per-app datasets/volumes on TrueNAS.
- k3s consumes storage via:
  - NFS dynamic provisioning, or
  - iSCSI/CSI path (based on your preferred controller).

### 6.2 Recommended Future Upgrade
Move from simple shared exports to a CSI-backed model with stronger volume lifecycle control.

Benefits:
- Better isolation.
- More natural snapshot/clone/restore logic.
- Cleaner ownership between compute and storage.

---

## 7) Security Model

### Principles
- Do not expose DNS (port `53`) to the internet.
- Cloudflare Tunnel only for HTTP/HTTPS.
- Admin access only through Tailscale.
- Secrets are never stored as plaintext in Git.

### Secrets
Choose one:

- `SOPS` (recommended for clean GitOps).
  - Encrypt `secrets.yaml` with `age/PGP`.
- `Sealed Secrets`.
  - Commit sealed secrets and decrypt in-cluster.

### Recommended Basic Hardening
- NetworkPolicies (when moving to Cilium/Calico).
- Namespace-scoped RBAC.
- Avoid privileged pods where possible.

---

## 8) Observability (Minimal -> Full)

### Recommended Minimum (Start Here)
- Prometheus
- Grafana
- Uptime Kuma

### Later Expansion
- Loki (logs)
- Alertmanager (alerts)

---

## 9) IaC: Terraform + Helm + GitOps

### 9.1 Operating Model
- Terraform:
  - Installs infra components (namespaces, Helm releases).
  - Can manage Cloudflare DNS records (optional).
- ArgoCD:
  - Manages apps and configs from a Git repo.

You can also let ArgoCD manage everything (including infra charts), but this split is often convenient:
- `Terraform = bootstrap`
- `ArgoCD = continuous sync`

---

## 10) Recommended Repository Structure

Repo 1: `infra-terraform`

```text
infra-terraform/
  providers.tf
  versions.tf
  variables.tf
  main.tf

  environments/
    prod/
      terraform.tfvars

  modules/
    k8s-ns/
    helm-adguard/
    helm-metallb/
    helm-cloudflared/
    helm-argocd/
    helm-traefik/
    helm-observability/
```

Repo 2: `homelab-gitops`

```text
homelab-gitops/
  apps/
    nextcloud/
    immich/
    vaultwarden/
    jellyfin/
    ...
  infra/
    dns/
      adguard/
    obs/
      grafana/
      prometheus/
  clusters/
    prod/
      kustomization.yaml (or apps-of-apps)
```

---

## 11) Components: Roles and Base Config

### 11.1 AdGuard Home
- Deployment/StatefulSet + PVC.
- Service:
  - `UDP/TCP 53`
  - UI on `3000/80` (depends on chart)
- Upstream DNS:
  - `https://1.1.1.1/dns-query`
  - `https://9.9.9.9/dns-query`

### 11.2 MetalLB (If Used)
- AddressPool from a free LAN range.
- Assign a fixed IP to the AdGuard Service.

### 11.3 Cloudflared
Tunnel with ingress rules:
- `nextcloud.yourdomain.com -> internal service`
- `immich.yourdomain.com -> internal service`

### 11.4 Traefik
- Ingress routes for services.
- If end-to-end TLS:
  - `cert-manager` with Cloudflare `DNS-01` challenge.

---

## 12) Router Integration (Critical)

On the router:
- DHCP provides DNS to clients:
  - Primary DNS: AdGuard IP (MetalLB or server IP).
  - Secondary DNS: ideally empty or same IP (to avoid bypassing filtering).
- Optional:
  - "Force DNS" feature (if the router can block clients from using custom DNS).

---

## 13) High Availability (Later)

- Current: Single node (reasonable for homelab).
- If k3s VM and TrueNAS VM are on the same physical host, hardware is still a single failure domain.
- Upgrade path:
  - 3-node k3s.
  - Dedicated storage host for TrueNAS (or replicated NAS target).
  - 2nd DNS fallback (for example another AdGuard instance or Unbound on router).

---

## 14) Failure Modes and Recovery

### DNS Down
- Symptom: whole house appears to lose internet.
- Mitigation:
  - health checks + auto-restart.
  - keep an emergency manual DNS option for quick router switch.
  - snapshots and fast restore.

### Disk/Storage
- Scheduled TrueNAS snapshots.
- Offsite backup (later): external disk / NAS / cloud sync.

---

## 15) Actionable Execution Checklist

### Phase 0: Prerequisites
- [ ] Active domain in Cloudflare.
- [ ] Hypervisor resources reserved for two VMs:
  - [ ] VM 1: Ubuntu + k3s (compute).
  - [ ] VM 2: TrueNAS (storage).
- [ ] Admin access through Tailscale.
- [ ] TLS strategy decision (Cloudflare-only or end-to-end).

### Phase 1: Cluster Bootstrap
- [ ] Install single-node k3s.
- [ ] Create namespaces: `infra`, `dns`, `apps`, `obs`.
- [ ] Install/confirm Traefik ingress (if customization is needed).
- [ ] Install ArgoCD in `infra`.
- [ ] Provision TrueNAS datasets and export method (NFS or iSCSI) for k3s.

Validation:
- [ ] `kubectl get nodes` is healthy.
- [ ] `kubectl get ns` includes all four namespaces.
- [ ] ArgoCD admin access is only through Tailscale.

### Phase 2: DNS Layer (Critical)
- [ ] Deploy AdGuard Home (`dns` namespace) with PVC.
- [ ] Decide and implement:
  - [ ] MetalLB + fixed LoadBalancer IP.
  - [ ] or NodePort on fixed server IP.
- [ ] Update DHCP/router: Primary DNS = AdGuard.
- [ ] Configure secure upstream DNS (DoH/DoT as needed).
- [ ] Ensure AdGuard PVCs are backed by TrueNAS-provided storage.

Validation:
- [ ] Clients receive AdGuard DNS from DHCP.
- [ ] Blocking works (known ad domain is blocked).
- [ ] DNS is not internet-exposed (external scan on port 53 is closed).

### Phase 3: Public Access via Cloudflare Tunnel
- [ ] Deploy cloudflared in `infra`.
- [ ] Create tunnel + secure token/credentials.
- [ ] Configure ingress rules (`nextcloud`, `immich`, etc.).
- [ ] Configure matching DNS records in Cloudflare.

Validation:
- [ ] Public services are reachable via domain.
- [ ] No router port-forwarding exists.

### Phase 4: GitOps + IaC
- [ ] Terraform bootstrap for infra Helm releases.
- [ ] ArgoCD sync for apps from `homelab-gitops`.
- [ ] Manage secrets with SOPS or Sealed Secrets.

Validation:
- [ ] `terraform plan` is clean (or only expected delta).
- [ ] ArgoCD is Synced/Healthy for core components.

### Phase 5: Observability + Recovery
- [ ] Deploy Prometheus + Grafana + Uptime Kuma.
- [ ] Configure health checks for DNS and ingress.
- [ ] Schedule TrueNAS snapshots.
- [ ] Run a small restore test (mini game day).

Validation:
- [ ] Basic dashboard is available to admin users.
- [ ] Alert triggers on AdGuard/Ingress failure.
- [ ] Restore test demonstrates acceptable RTO.
