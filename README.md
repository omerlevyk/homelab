# Homelab

Infrastructure-as-code and GitOps configuration for my Kubernetes homelab.
The repository contains Terraform infrastructure, Argo CD application
definitions, and supporting operational documentation.

## Documentation

- [Documentation index](docs/README.md)
- [Architecture](docs/architecture.md)
- [Argo CD operating model](docs/argocd-operating-model.md)
- [Hardware inventory](docs/hardware.md)
- [Current work and roadmap](docs/jobs.md)
- [Terraform configuration](terraform/README.md)

## Repository layout

- `gitops/` — cluster and application manifests managed through Argo CD
- `terraform/` — infrastructure provisioning and provider configuration
- `docs/` — architecture, operations, hardware, and project notes

> This repository describes a personal environment. Review addresses,
> credentials, storage classes, and hardware-specific values before reusing
> any configuration.
