# Hardware Log

Date created: 2026-05-01
Owner: Omer

## System
- Model: Dell OptiPlex 7070 Tower
- RAM: 16 GB
- Storage:
  - SSD 1: `447.1G` `PNY CS900 480GB`
  - SSD 2: `238.5G` `KBG40ZNS256G NVMe TOSHIBA 256GB`
- Intended OS: Ubuntu Server

## Hardware Inventory

### homeserver
- RAM: `7.6 GiB`
- Storage:
  - The `931.5G` `ST1000LM024 HN-M` HDD was removed and moved to `homeserver2` on `2026-05-21`.
  - Previous layout before removal:
    - `sda1` `1G` mounted at `/boot/efi`
    - `sda2` `2G` mounted at `/boot`
    - `sda3` `928.5G` backing `ubuntu--vg-ubuntu--lv`, mounted at `/`

### homeserver2
- RAM: `15 GiB`
- Storage:
  - `447.1G` `PNY CS900 480GB`
  - `931.5G` `ST1000LM024 HN-M`
  - `238.5G` `KBG40ZNS256G NVMe TOSHIBA 256GB`
  - `411.8M` optical drive `PLDS DVD+/-RW DU-8A5LH`
  - Layout:
    - `sda1` `1G` mounted at `/boot/efi`
    - `sda2` `2G` mounted at `/boot`
    - `sda3` `444.1G` with `ubuntu--vg-ubuntu--lv` mounted at `/`
    - `/` expanded to full LV size: `437G` total, `411G` free at check time
    - `sdb1` `931.5G` formatted as `ext4` and mounted at `/srv`
    - `/srv` capacity at check time: `916G` total, `870G` free
    - `nvme0n1p1` `238.5G` formatted as `ext4` and mounted at `/data`
    - `/data` capacity at check time: `234G` total, `222G` free
- Intended role split:
  - SSD (`sda`): Ubuntu + k3s
  - HDD (`sdb1` mounted at `/srv`): main persistent homelab / k3s storage
  - NVMe (`/data`): optional fast storage for app-specific data, downloads, cache, or transcode

## Installation Log

### 2026-05-01
- Started Ubuntu Server installation on the Dell OptiPlex 7070 Tower.
- Initial install choice:
  - Selected `Ubuntu Server` instead of `Ubuntu Server (minimized)`.

### 2026-05-05
- Ubuntu Server installation completed.
- Hostname set to `homeserver2`.
- Confirmed LAN IP address: `192.168.1.101`.
- Installed `OpenSSH server`.
- Chose not to import SSH identity during installation.
- Configured SSH key-based access from the existing workstation.
- SSH client alias configured:
  - `ssh homeserver2`
- Shell environment updated:
  - `~/.bashrc` reloaded
  - prompt configured to use `oh-my-posh`
- Config file copied from `homeserver` to `homeserver2`:
  - `~/.config/minimal_gruvbox.opm.json`
- Post-install packages/tools installed or requested:
  - `htop`
  - `tree`
  - `oh-my-posh` installed to `~/.local/bin`
  - `lazygit` requested

### 2026-05-09
- Expanded `ubuntu--vg-ubuntu--lv` on `sda3` from `100G` to the full available size on the `447.1G` SSD.
- Wiped the old partition layout on `nvme0n1`.
- Created a new single `ext4` partition on `nvme0n1p1`.
- Mounted the NVMe disk at `/data` and added a persistent `/etc/fstab` entry using filesystem UUID `711d5d34-f54f-46ee-b0ca-6fe4eac8cf2a`.
- Validation after changes:
  - `/` = `437G` total, `411G` free
  - `/data` = `234G` total, `222G` free

## Pending Details
- CPU model
- BIOS settings used


### 2026-05-21
- Moved the `931.5G` `ST1000LM024 HN-M` HDD from `homeserver` to `homeserver2`.
- Confirmed the moved disk initially appeared on `homeserver2` as `/dev/sdb` with the old Ubuntu partition table and duplicate `ubuntu-vg` LVM metadata.
- Wiped the old disk signatures and repartitioned the HDD as a single `ext4` filesystem on `/dev/sdb1`.
- Mounted the HDD at `/srv` and added a persistent `/etc/fstab` entry using filesystem UUID `ea102cbf-e8c9-4ae7-8e4b-167e04ec7d92`.
- Confirmed the duplicate LVM conflict was resolved after the HDD wipe; only the SSD-backed `ubuntu-vg` remains active.
- Installed k3s on `homeserver2`.
- Updated the k3s `local-path` provisioner to use `/srv/local-path-provisioner` on the HDD instead of the default SSD-backed path under `/var/lib/rancher/k3s/storage`.
- Validated dynamic PVC provisioning on the HDD by creating a test claim and test pod; confirmed data was written under `/srv/local-path-provisioner/.../probe.txt`.
- Created `/srv/media` on the HDD for the static media PV expected by the GitOps manifests.
- Generated a remote kubeconfig for `homeserver2` using `https://192.168.1.101:6443` and copied it to `omerPC` as `~/.kube/homeserver2-k3s.yaml`.
- Verified remote cluster access from `omerPC` with `kubectl --kubeconfig ~/.kube/homeserver2-k3s.yaml get nodes`.
- Updated Terraform usage to target `homeserver2` and applied the bootstrap namespaces (`apps`, `dns`, `infra`, `obs`) to the new cluster.

## Next Steps
- Make DNS configuration on `homeserver2` persistent so package installs, image pulls, and cluster operations survive reboot without the temporary `resolvectl` override.
- Bootstrap ArgoCD on `homeserver2` with Terraform using the new kubeconfig.
- Keep Terraform as the owner of bootstrap namespaces and remove duplicate namespace creation from GitOps if not already cleaned up.
- Create the `cloudflared-token` secret on `homeserver2` before applying the Cloudflare tunnel workload.
- Reconcile the GitOps stack against `homeserver2` and verify storage-backed apps bind to the new HDD layout.
- Review Cloudflare Terraform authentication and switch to a valid scoped API token before managing tunnel and DNS resources again.
