# Fixing OAuth state

This might happen if OAuth Identity Provider re-creates users with new IDs and some OAuth/OpenID Connect logins break because of it.

### Immich

1. Got to `https://immich.<domain>/user-settings?isOpen=oauth`
2. Unlink OAuth
3. Log out
4. Log in with using IdP

### Paperless

1. Go to `https://paperless.<domain>/admin/socialaccount/socialaccount/` as admin
2. Find account of a `<user>`, and delete it
3. Log out
4. Log in as a `<user>` using password
5. Go to `https://paperless.<domain>/accounts/oidc/<provider-name>/login/?process=connect`
6. Connect account with IdP

### Jellyfin

1. Go to `http://jellyfin.<domain>/SSOViews/linking`.
2. Unlink OAuth
3. Log out
4. Log in using IdP

### Audiobookshelf

1. Log in using password as an admin
2. Go to `https://audiobookshelf.<domain>/audiobookshelf/config/users` and unlink user(s)
3. Log out
4. Log in using IdP

### Grist

No action needed. Seems like grist matches only by username/email and automatically picks-up changes.

### Home-Assistant

No action needed (I think). HA plugin matches users by username and automatically picks-up changes.
Welcome URL is `https://homeassistant.<domain>/auth/oidc/welcome`

### Dashy

Log out and log in. No extra actions needed. Dashy only cares about groups/roles and doesn't keep the user info.
