# Setting up Tailscale

## Split DNS

In local network I have router setup that it resolves `*.server.lan` addresses to the server. The problem is that Tailscale is running only on the server and doesn't have access to LAN, so it can't resolve those queries. There's a [proposal](https://github.com/tailscale/tailscale/issues/1543) in Taislcale's Github to allow custom records in their Magic DNS, but until it's implemented another solution has to be used.

### DNS Server running on the same machine as Tailscale

Running a DNS server on the same machine (and interface) as Tailscale pointing to this machine's Tailscale IP address as the destination for `*.server.lan` solves the issue. This way the queries in LAN are resolved by the Router, while the queries on Tailnet by the machine itself.

It's not ideal, but it works. Here's how to set this up:

### Terraform

There's a terraform module available to set most of the things automatically.

1. Generate new [Auth Key](https://tailscale.com/kb/1085/auth-keys) for the server
2. Add it to `home-server-nixos-secrets`
3. Fetch new secrets in this repo `nix flake update home-server-nixos-secrets`
4. Deploy new config, make sure the machine shows up in the [Tailscale Admin page](https://login.tailscale.com/admin/machines)
5. Enter the terraform shell with `just tf-shell` or `nix develop .#tf`
6. Go to `terraform/tailscale` and run `terraform init` && `terraform apply`.
   1. This will setup the DNS in Tailscale and will disable key expiry for the server and update/create a `managed-files/server_addresses.json` file
7. Rebuild NixOS

Now `*.server.lan` domains are accessible from Tailscale network
