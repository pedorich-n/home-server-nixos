{ hostname, domain, lib, customLib, ... }:
let
  inherit (lib) tfRef;
in
{
  data = {
    # Schema https://registry.terraform.io/providers/tailscale/tailscale/0.17.2/docs/data-sources/device
    tailscale_device.server = {
      hostname = "${hostname}";
    };

    # https://registry.terraform.io/providers/1Password/onepassword/2.1.2/docs/data-sources/vault
    onepassword_vault.homelab = {
      name = "HomeLab";
    };

    onepassword_item = {
      tailscale = {
        vault = tfRef "data.onepassword_vault.homelab.uuid";
        title = "Tailscale";
      };
    };
  };


  locals = {
    secrets = {
      tailscale = customLib.mkOnePasswordMapping "tailscale";
    };
  };

  resource = {
    # Schema https://registry.terraform.io/providers/tailscale/tailscale/0.17.2/docs/resources/dns_nameservers
    tailscale_dns_nameservers.global_dns = {
      nameservers = [
        "1.1.1.1"
        "9.9.9.9"
      ];
    };

    # Schema https://registry.terraform.io/providers/tailscale/tailscale/0.17.2/docs/resources/dns_split_nameservers
    tailscale_dns_split_nameservers.server = {
      inherit domain;
      nameservers = tfRef "data.tailscale_device.server.addresses";
    };

    # Schema https://registry.terraform.io/providers/tailscale/tailscale/0.17.2/docs/resources/device_key
    tailscale_device_key.server = {
      device_id = tfRef "data.tailscale_device.server.id";
      key_expiry_disabled = true;
    };

  };
}
