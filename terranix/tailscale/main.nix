{ flake, ... }:
let
  serverCfg = flake.nixosConfigurations.geekomA5.config;

  hostname = serverCfg.networking.hostName;
  domain = serverCfg.custom.networking.domain;
in
{
  data = {
    # Schema https://registry.terraform.io/providers/tailscale/tailscale/0.17.2/docs/data-sources/device
    "tailscale_device"."server" = {
      hostname = "${hostname}";
    };
  };

  resource = {
    # Schema https://registry.terraform.io/providers/tailscale/tailscale/0.17.2/docs/resources/dns_nameservers
    "tailscale_dns_nameservers"."global_dns" = {
      nameservers = [
        "1.1.1.1"
        "9.9.9.9"
      ];
    };

    # Schema https://registry.terraform.io/providers/tailscale/tailscale/0.17.2/docs/resources/dns_split_nameservers
    "tailscale_dns_split_nameservers"."server" = {
      inherit domain;
      nameservers = "\${data.tailscale_device.server.addresses}";
    };

    # Schema https://registry.terraform.io/providers/tailscale/tailscale/0.17.2/docs/resources/device_key
    "tailscale_device_key"."server" = {
      device_id = "\${data.tailscale_device.server.id}";
      key_expiry_disabled = true;
    };

  };
}
