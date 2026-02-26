# Setting up OAuth in Forgejo CLI

```bash
❯ nix shell nixpkgs#forgejo

❯ sudo -u forgejo forgejo admin auth add-oauth \
  --work-path /var/lib/forgejo \
  --provider=openidConnect \
  --name=authelia \
  --key="<CLIENT_ID>" \
  --secret="<CLIENT_SECRET>" \
  --auto-discover-url="https://authelia.<DOMAIN>/.well-known/openid-configuration" \
  --scopes="openid email profile groups" \
  --group-claim-name="groups" \
  --admin-group="Admins"

```
