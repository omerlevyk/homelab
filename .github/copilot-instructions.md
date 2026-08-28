# Homelab Copilot Instructions

This repository manages the production `homeserver` single-node k3s homelab.
Treat every change as infrastructure: keep patches small, preserve GitOps
ownership, and call out availability or data risks.

## Repository map

- `terraform/` bootstraps namespaces, ArgoCD, and optional Cloudflare
  tunnel/DNS resources. Run Terraform commands from this directory.
- `gitops/` is the desired state reconciled by ArgoCD.
- `gitops/apps/<app>/`, `gitops/infra/<component>/`, `gitops/dns/adguard/`, and
  `gitops/obs/<component>/` hold Kustomize-managed workloads.
- `gitops/app-deployments/` holds standalone manifests selected by the
  `app-deployments` ApplicationSet in `gitops/clusters/prod/app-deployments.yaml`.
- `gitops/clusters/prod/` is the root/bootstrap layer. Its `appset.yaml` and
  `app-deployments.yaml` define the application catalog; keep the root thin.
- `docs/` records architecture and operating decisions. Read
  `docs/argocd-operating-model.md` before changing ArgoCD ownership, catalog
  structure, or sync waves, and update relevant documentation with behavior
  changes.

## Kubernetes and GitOps rules

- Follow the nearest existing manifest's naming, labels, namespaces, ports, and
  resource ordering. Preserve selectors, Service targets, PVC names, and
  ConfigMap/Secret references unless all consumers are updated together.
- Add each new file to its owning `kustomization.yaml`. Do not place ordinary
  application resources directly in `gitops/clusters/prod/kustomization.yaml`.
- When adding a Kustomize-managed child app, add its catalog entry to
  `gitops/clusters/prod/appset.yaml`, with the correct namespace and sync wave.
  When adding a standalone app-deployment manifest, add the matching entry and
  include pattern to `app-deployments.yaml` instead.
- Keep namespaces explicit where nearby manifests do. Cluster-scoped resources
  must not receive a namespace.
- New workloads should use an explicit image tag; do not silently alter an
  existing image-tag strategy. Use `Asia/Jerusalem` for application timezone
  configuration when appropriate.
- Stateful changes are high risk: require appropriate persistent storage,
  resource requests/limits, and supported health probes. Clearly flag PV/PVC,
  storage class, reclaim policy, and volume-name changes.
- Cloudflare Tunnel is the public HTTP(S) ingress path. Do not introduce direct
  public exposure, host ports, or port-forwarding dependencies. Keep admin
  access on LAN/Tailscale paths. Never expose DNS port 53 publicly.

## Secrets and safety

- Never commit plaintext credentials, tokens, private keys, kubeconfigs, or
  private network details. Reference an existing Secret and document required
  keys or manual bootstrap steps in the component README when needed.
- Do not rotate, replace, or apply live secrets as part of a normal manifest
  change. Changes to `dns` resources need an explicit rollback plan because they
  can disrupt the whole network.
- Do not run `terraform apply`, destructive commands, or live `kubectl` write
  operations unless the user explicitly asks. For high-risk changes, state the
  rollout order, impact, and rollback path.

## Terraform and validation

- Keep Terraform idiomatic. Do not add provider credentials to `.tf`,
  `.tfvars`, examples, or documentation; Cloudflare credentials come from the
  environment.
- Before an apply, review `terraform plan -var-file=env/prod/terraform.tfvars`
  and verify the kubeconfig context is `homeserver`. Highlight replacements,
  namespace changes, persistent-volume changes, and Cloudflare DNS/route changes.
- For Terraform edits, run `terraform fmt -check` and, after initialization,
  `terraform validate` from `terraform/`.
- For GitOps edits, render the affected Kustomize entry point when tooling is
  available, for example `kubectl kustomize gitops/apps/<app>`. Check that every
  referenced file, ApplicationSet path, namespace, and resource name exists.
- Keep YAML two-space indented and consistent with surrounding manifests. Avoid
  unrelated reformatting and generated-file churn; mention assumptions and any
  manual secret/bootstrap work in the change summary.
