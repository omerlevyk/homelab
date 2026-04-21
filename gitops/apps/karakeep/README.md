# Karakeep

Private-only Karakeep deployment for `karakeep.home.arpa`.

Before syncing the app, create the required secret in the `apps` namespace:

```sh
kubectl -n apps create secret generic karakeep-secrets \
  --from-literal=NEXTAUTH_SECRET="$(openssl rand -base64 36)" \
  --from-literal=MEILI_MASTER_KEY="$(openssl rand -base64 36 | tr -dc 'A-Za-z0-9')"
```

The initial deployment leaves `DISABLE_SIGNUPS=false` so the first account can be created. After bootstrap, set it to `"true"` in `deploy.yaml` and sync again.

Also add an AdGuard DNS rewrite for:

```text
karakeep.home.arpa -> 192.168.1.234
```
