# Setting up Tailscale

1. After a machine has been added to the network for the first time go to [Tailscale Admin page](https://login.tailscale.com/admin/machines)
2. Copy the machine's IP
3. Go to [DNS](https://login.tailscale.com/admin/dns) settings. Under "Nameservers" add new Custom name server:
   1. Set address to the machine's IP
   2. Enable Split DNS and set the domain to `server.local`
4. In this repo modify `tailscale/default.nix`
   1. Set `tailscaleMachineIp` to Machine's IP from Tailscale Admin
5. PROFIT

Now `*.server.local` domains are accessible from both LAN and Tailscale network
