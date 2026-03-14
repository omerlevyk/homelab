# Vaultwarden

Private-only password manager for LAN and Tailscale clients.

## Access model
- Internal hostname: `vaultwarden.home.arpa`
- No public Cloudflare Tunnel route
- Intended client access: LAN or Tailscale only

## Post-sync requirements
Create an AdGuard DNS rewrite so `vaultwarden.home.arpa` resolves to the Traefik entrypoint IP used by the rest of the `*.home.arpa` apps.

Current homelab baseline:
- target IP: `192.168.1.234`

Recommended AdGuard rewrite:
- domain: `vaultwarden.home.arpa`
- answer: `192.168.1.234`

## Security notes
- `SIGNUPS_ALLOWED=false`
- `INVITATIONS_ALLOWED=false`
- Keep this app private-only
- Add HTTPS before using it as a daily driver from mobile clients
