{ serverConfig, lib, ... }:
let
  inherit (lib) tfRef;

  hostname = serverConfig.networking.hostName;
  domain = serverConfig.custom.networking.domain;
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
      nameservers = tfRef "data.tailscale_device.server.addresses";
    };

    # Schema https://registry.terraform.io/providers/tailscale/tailscale/0.17.2/docs/resources/device_key
    "tailscale_device_key"."server" = {
      device_id = tfRef "data.tailscale_device.server.id";
      key_expiry_disabled = true;
    };

  };
}
