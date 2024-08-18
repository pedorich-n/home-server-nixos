# Setting up Tailscale

## Split DNS

In local network I have router setup that it resolves `*.server.lan` addresses to the server. The problem is that Tailscale is running only on the server and doesn't have access to LAN, so it can't resolve those queries. There's a [proposal](https://github.com/tailscale/tailscale/issues/1543) in Taislcale's Github to allow custom records in their Magic DNS, but until it's implemented another solution has to be used.

### DNS Server running on the same machine as Tailscale

Running a DNS server on the same machine (and interface) as Tailscale pointing to this machine's Tailscale IP address as the destination for `*.server.lan` solves the issue. This way the queries in LAN are resolved by the Router, while the queries on Tailnet by the machine itself.

It's not ideal, but it works. Here's how to set this up:

1. After a machine has been added to the network for the first time go to [Tailscale Admin page](https://login.tailscale.com/admin/machines)
2. Copy the machine's IP
3. Go to [DNS](https://login.tailscale.com/admin/dns) settings. Under "Nameservers" add new Custom name server:
   1. Set address to the machine's IP
   2. Enable Split DNS and set the domain to `server.lan`
4. Modify `machines/geekomA5/modules/system/services/server-management/tailscale.nix`
   1. Set `tailscaleMachineIp` to Machine's IP from Tailscale Admin
5. PROFIT

Now `*.server.lan` domains are accessible from Tailscale network
