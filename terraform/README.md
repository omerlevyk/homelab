# terraform

Terraform bootstrap layer for the homelab k3s cluster.

This repo should target `homeserver`, which is now the active cluster node.

## Current Scope
- Provider wiring (`kubernetes`, `helm`, `cloudflare`)
- Core namespaces managed by Terraform:
  - `infra`
  - `dns`
  - `apps`
  - `obs`
- ArgoCD Helm module
- Cloudflare tunnel route module scaffolded (disabled by default)

## Usage (from `omerPC`)
```bash
cd /home/omer/homelab/homelab-repo/terraform
cp env/prod/terraform.tfvars.example env/prod/terraform.tfvars
terraform init
kubectl config current-context
kubectl cluster-info
terraform plan -var-file=env/prod/terraform.tfvars
```

Enable Cloudflare route management when ready:
```bash
export CLOUDFLARE_API_TOKEN='<token-with-tunnel-and-dns-permissions>'
terraform plan -var-file=env/prod/terraform.tfvars -var='enable_cloudflare_tunnel_routes=true'
```

## Notes
- Verify the kubeconfig path/context point at `homeserver` before every Terraform apply.
- Keep homelab kubeconfig isolated from other projects.
- Do not commit Cloudflare API tokens to git; use environment variables.
- Avoid applying destructive changes to `dns` resources without a backup/rollback plan.

## Recovery Notes

### 2026-05-26 to 2026-06-06

What we fixed:
- Confirmed the live cluster is `homeserver` via `/home/omer/.kube/homeserver-k3s.yaml`.
- Identified that `~/.kube/config` was pointing to `homeserver-k3s-tunnel.yaml` using `https://127.0.0.1:16443`, and that local tunnel endpoint was down.
- Restored the media stack by clearing the stale static PV binding on `jellyfin-media-pv`:

```bash
kubectl patch pv jellyfin-media-pv --type=json -p='[{"op":"remove","path":"/spec/claimRef"}]'
```

- Rebound `apps/jellyfin-media-pvc` to `jellyfin-media-pv`, which unblocked:
  - `jellyfin`
  - `qbittorrent`
  - `sonarr`
  - `radarr`
  - `lidarr`
  - `bazarr`
  - `tdarr`
- Restored `cloudflared` by replacing the placeholder secret value in `infra/cloudflared-token` with a real connector token and restarting the deployment.
- Resolved the Kubernetes-level `igotify` failure by creating the missing secret `apps/igotify-local-instance` and restarting the deployment.

Current status:
- Cluster workloads are running again on `homeserver`.
- `cloudflared` is connected and receiving Cloudflare tunnel config.
- The shared Jellyfin media PV/PVC is bound again.
- `igotify` now starts, but its application config still needs real values.

What is still left:
- Replace placeholder values in `apps/igotify-local-instance`:
  - `gotify_urls`
  - `gotify_client_tokens`
  - `secntfy_tokens`
- Verify `gotify_urls` points to the real in-cluster Gotify service, not a placeholder string.
- Rotate the Cloudflare connector token because it was exposed during manual recovery, then update `infra/cloudflared-token` again.
- Consider repointing `~/.kube/config` away from the dead `homeserver-k3s-tunnel.yaml` symlink to avoid future confusion.
- Verify ArgoCD application health/sync status after manual secret fixes.

Notes:
- `gitops/infra/cloudflared/README.md` documents the required secret, but the live failure was caused by the secret containing example text instead of a real token.
- `gitops/apps/igotify/deploy.yaml` expects a manually supplied secret and will fail with `CreateContainerConfigError` if `igotify-local-instance` is absent.
