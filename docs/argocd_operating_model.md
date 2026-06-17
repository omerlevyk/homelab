# ArgoCD Operating Model

Date: 2026-06-15
Owner: Omer
Scope: steady-state GitOps operating model for the `homeserver` single-node k3s cluster.

## Purpose

This document defines what the ArgoCD root app owns, what child apps own, and how to operate the repo day to day without reintroducing a monolithic root app.

## Current Model

ArgoCD uses an app-of-apps layout.

- Root application: `homelab-root`
- Child applications: one ArgoCD `Application` per infra service or workload
- ArgoCD namespace: `infra`
- Runtime cluster target: `homeserver`

The goal is:
- `homelab-root` declares the application catalog
- child applications own the actual workload manifests
- day-2 operations happen on child apps, not on the root app

## What `homelab-root` Owns

`homelab-root` should remain thin.

It owns only:
- ArgoCD self-management resources under `gitops/infra/argocd`
- shared bootstrap resources that must exist before normal child apps
- child ArgoCD `Application` manifests under `gitops/clusters/prod/applications`
- shared CRD/bootstrap layers that are intentionally managed at the root level

It should not directly own ordinary app workloads from `gitops/apps/*`.

## What Child Applications Own

Each child `Application` owns one workload or infra component.

Examples:
- infra children:
  - `adguard`
  - `cloudflared`
  - `traefik-dashboard`
- observability/shared-service children:
  - `kube-prometheus-stack`
  - `homepage`
  - `gotify`
  - `igotify`
  - `uptime-kuma`
- normal app children:
  - `jellyfin`
  - `qbittorrent`
  - `prowlarr`
  - `sonarr`
  - `radarr`
  - `lidarr`
  - `bazarr`
  - `overseerr`
  - `tdarr`
  - `vaultwarden`
  - `syncthing`
  - `home-assistant`
  - `karakeep`

Each child app owns:
- sync state
- prune behavior
- diff/health visibility
- rollback history
- its own manifests in `gitops/apps`, `gitops/infra`, or `gitops/obs`

## Repo Layout

Relevant layout:

```text
gitops/clusters/prod/
  kustomization.yaml
  applications/
    kustomization.yaml
    *.yaml

gitops/infra/
  argocd/
  cloudflared/
  dns/adguard/
  traefik-dashboard/

gitops/apps/
  <app>/

gitops/obs/
  prometheus-operator-crds/
  kube-prometheus-stack/
```

Rule:
- add new workloads as child `Application` manifests under `gitops/clusters/prod/applications/`
- do not add normal app workload directories directly back into `gitops/clusters/prod/kustomization.yaml`

## Sync Waves

Current sync-wave model:

- wave `0`
  - root/bootstrap layer
- wave `1`
  - infra dependencies
  - `adguard`
  - `cloudflared`
  - `traefik-dashboard`
- wave `2`
  - observability and shared services
  - `kube-prometheus-stack`
  - `homepage`
  - `gotify`
  - `igotify`
  - `uptime-kuma`
- wave `3`
  - normal application workloads
  - media apps
  - personal apps
  - stateful service apps

Meaning:
- lower wave numbers should become ready before higher wave numbers during root-driven syncs
- routine updates to a single child app can still be synced independently

## Day-2 Operations

Use `homelab-root` only when:
- adding a new child application
- removing a child application
- moving an app to a different repo path
- changing root/bootstrap wiring
- changing sync-wave ordering or child app declarations

Use child applications when:
- syncing a changed app
- refreshing app status
- reviewing diffs
- debugging health or drift
- retrying failed rollouts
- rolling back one app

## Practical Rules

- Sync `homelab-root` when the application catalog changes.
- Sync child apps when their workload manifests change.
- Start debugging at the child app level first.
- Keep root small and predictable.
- Avoid mixing CRD/bootstrap concerns with normal app ownership unless there is a clear reason.

## Change Workflow

When adding a new app:
1. Create the workload manifests under the correct repo path.
2. Add a child `Application` manifest under `gitops/clusters/prod/applications/`.
3. Assign the correct destination namespace.
4. Assign the correct sync wave.
5. Sync `homelab-root` so ArgoCD creates the child app.
6. Verify the new child app becomes `Healthy` and `Synced`.

When changing an existing app:
1. Edit the app manifests under its owned path.
2. Commit and push.
3. Sync only that child app unless the root catalog changed.

## Anti-Patterns To Avoid

- putting normal workload directories directly under `gitops/clusters/prod/kustomization.yaml`
- using `homelab-root` for routine app rollouts
- changing many unrelated apps through the root app when only one child app changed
- mixing bootstrap ownership and workload ownership without documenting why

## Current Success Criteria

The operating model is considered correct when:
- `homelab-root` stays thin
- each major service appears as its own ArgoCD `Application`
- child apps are the main unit of sync and troubleshooting
- sync order is deterministic through waves
- repo structure reflects the ownership model clearly
