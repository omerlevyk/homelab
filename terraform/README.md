# terraform

Terraform bootstrap layer for the homelab k3s cluster.

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
cp environments/prod/terraform.tfvars.example environments/prod/terraform.tfvars
terraform init
terraform plan -var-file=environments/prod/terraform.tfvars
```

Enable Cloudflare route management when ready:
```bash
export CLOUDFLARE_API_TOKEN='<token-with-tunnel-and-dns-permissions>'
terraform plan -var-file=environments/prod/terraform.tfvars -var='enable_cloudflare_tunnel_routes=true'
```

## Notes
- Keep homelab kubeconfig isolated from other projects.
- Do not commit Cloudflare API tokens to git; use environment variables.
- Avoid applying destructive changes to `dns` resources without a backup/rollback plan.
