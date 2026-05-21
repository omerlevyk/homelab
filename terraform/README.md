# terraform

Terraform bootstrap layer for the homelab k3s cluster.

This repo should target `homeserver2`, not the retired `homeserver` node.

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
- Verify the kubeconfig path/context point at `homeserver2` before every Terraform apply.
- Keep homelab kubeconfig isolated from other projects.
- Do not commit Cloudflare API tokens to git; use environment variables.
- Avoid applying destructive changes to `dns` resources without a backup/rollback plan.
