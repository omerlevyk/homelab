# kube-prometheus-stack

This ArgoCD application installs Prometheus and Grafana into the `obs` namespace from the official `prometheus-community/kube-prometheus-stack` Helm chart.

## Scope
- Prometheus
- Grafana
- Prometheus Operator
- kube-state-metrics
- node-exporter

## Intentional exclusions for this homelab baseline
- `Alertmanager` disabled for now
- `kubeEtcd`, `kubeControllerManager`, `kubeScheduler`, and `kubeProxy` scrapes disabled to avoid noisy single-node k3s failures

## Private access
- Grafana: `http://grafana.home.arpa`
- Prometheus: `http://prometheus.home.arpa`

These hostnames still need matching AdGuard DNS rewrites if they are not already covered by your wildcard/internal DNS path.

## Grafana login
The chart creates the Grafana admin secret in-cluster. After sync, retrieve it with:

```bash
kubectl -n obs get secret obs-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo
```
