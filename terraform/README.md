# infra-terraform

Terraform bootstrap layer for the homelab k3s cluster.

## Current Scope
- Provider wiring (`kubernetes`, `helm`)
- Core namespaces managed by Terraform:
  - `infra`
  - `dns`
  - `apps`
  - `obs`
- ArgoCD Helm module scaffolded (disabled by default via `enable_argocd_bootstrap = false`)

## Planned Scope
- Helm modules for:
  - ArgoCD
  - Cloudflared
  - AdGuard
  - (optional) MetalLB / observability

## Usage (from `omerPC`)
```bash
cd /home/omer/homelab/infra-terraform
cp environments/prod/terraform.tfvars.example environments/prod/terraform.tfvars
terraform init
terraform plan -var-file=environments/prod/terraform.tfvars
```

Enable ArgoCD bootstrap when ready:
```bash
terraform plan -var-file=environments/prod/terraform.tfvars -var='enable_argocd_bootstrap=true'
```

## Notes
- Keep kubeconfig on `omerPC` pointed to the `homeserver` k3s cluster.
- Avoid applying destructive changes to `dns` resources without a backup/rollback plan.
