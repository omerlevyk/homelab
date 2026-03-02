# cloudflared

This deployment expects an existing secret in namespace `infra`:

- Secret name: `cloudflared-token`
- Key: `token`

Create/update it before syncing:

```bash
kubectl -n infra create secret generic cloudflared-token \
  --from-literal=token='<CLOUDFLARE_TUNNEL_TOKEN>' \
  --dry-run=client -o yaml | kubectl apply -f -
```

