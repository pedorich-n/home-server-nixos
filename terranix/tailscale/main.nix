{ flake, ... }:
let
  serverCfg = flake.nixosConfigurations.geekomA5.config;

  hostname = serverCfg.networking.hostName;
  domain = serverCfg.custom.networking.domain;
in
{
  data = {
    "tailscale_device"."server" = {
      hostname = "${hostname}";
    };
  };

  resource = {
    "tailscale_dns_nameservers"."global_dns" = {
      nameservers = [
        "1.1.1.1"
        "9.9.9.9"
      ];
    };

    "tailscale_dns_split_nameservers"."server" = {
      inherit domain;
      nameservers = "\${data.tailscale_device.server.addresses}";
    };

    "tailscale_device_key"."server" = {
      device_id = "\${data.tailscale_device.server.id}";
      key_expiry_disabled = true;
    };

  };
}
