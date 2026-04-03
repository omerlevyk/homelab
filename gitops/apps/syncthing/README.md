# Syncthing

Private-only file sync hub for LAN and Tailscale clients.

## Access model
- Web UI: `syncthing.home.arpa`
- No public Cloudflare Tunnel route
- Intended client access: LAN or Tailscale only

## Storage model
- Config PVC: `syncthing-config-pvc` (`2Gi`, `local-path`)
- Data PVC: `syncthing-data-pvc` (`100Gi`, `local-path`)
- Main synced folder mount inside the container: `/data`

## Networking notes
- Web UI stays private behind Traefik ingress
- Device sync ports are exposed only on the local node via the `LoadBalancer` service:
  - TCP `22000`
  - UDP `22000`
  - UDP `21027`

## Post-sync requirements
Create an AdGuard DNS rewrite so `syncthing.home.arpa` resolves to the Traefik entrypoint IP used by the rest of the `*.home.arpa` apps.

Current homelab baseline:
- target IP: `192.168.1.234`

Recommended AdGuard rewrite:
- domain: `syncthing.home.arpa`
- answer: `192.168.1.234`

## First-run notes
- Finish the initial Syncthing web UI setup before pairing devices
- Create a top-level folder under `/data` for each sync set you want to share
- Keep this app private-only
