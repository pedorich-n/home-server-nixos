# Safebucket OIDC Admin

Safebucket currently doesn't support changing role for an OIDC user via the admin panel, so it needs to be done manually.

1. Locate Safebucket SQLite DB
2. Using SQLite CLI open the DB
3. Run the query `update users set role = 'admin' where email = '<email>';`
