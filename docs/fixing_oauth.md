# Fixing OAuth state after Authentik update

This happens when Authentik is redeployed and blueprints ran. The data in DB gets overwritten with new IDs and some OAuth/OpenID Connect logins break because of it.

### Immich

1. Go to [Portainer](http://portainer.server.lan/)
2. Go to `immich-posgtres` container, open console
3. `psql -U immich`
4. `update users set "oauthId" = '' where email = '<email>';`
5. Re-login to Immich using Authentik

### Paperless

1. Login to [Paperless](http://paperless.server.lan) using admin credentials
2. Go to [admin, Social Accounts](http://paperless.server.lan/admin/socialaccount/socialaccount/) as admin
3. Find account of a `<user>`, and delete it
4. Log out
5. Log in as a `<user>` using password
6. Go to [Social Connections](http://paperless.server.lan/accounts/social/connections/)
7. Connect account with Authentik
