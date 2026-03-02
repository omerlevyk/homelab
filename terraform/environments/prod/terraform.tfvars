cluster_name       = "homeserver-k3s"
kubeconfig_path    = "~/.kube/homeserver-k3s-tunnel.yaml"
kubeconfig_context = "default"

enable_argocd_bootstrap         = true

enable_cloudflare_tunnel_routes = true
cloudflare_account_id           = "68c7c95acd572ff0f010859b507fbbf8"
cloudflare_zone_id              = "8c97e7ebab9dc3e0ee71ff49b653ecfa"
cloudflare_zone_name            = "omerlevy03.com"
cloudflare_tunnel_id            = "f8cd700f-3ee1-4d96-a255-0326ba806c44"

cloudflare_public_hostnames = {
  whoami = { service = "http://whoami.infra.svc.cluster.local:80" }
}
