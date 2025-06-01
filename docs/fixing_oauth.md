# Fixing OAuth state after Authentik update

This rarely happens when Authentik blueprint re-creates users with new IDs and some OAuth/OpenID Connect logins break because of it.

### Immich

1. Go to `immich-postgresql` container, open console
2. `psql -U immich`
3. `update users set "oauthId" = '' where email = '<email>';`
4. Re-login to Immich using Authentik

### Paperless

1. Go to `http://paperless.<domain>/admin/socialaccount/socialaccount/` as admin
2. Find account of a `<user>`, and delete it
3. Log out
4. Log in as a `<user>` using password
5. Go to `http://paperless.<domain>/accounts/oidc/authentik/login/?process=connect`
6. Connect account with Authentik

### Jellyfin

Haven't had a case of broken connection yet, so don't know if it'll help, but there's a page to link/unlink SSO accounts: `http://jellyfin.<domain>/SSOViews/linking`.
