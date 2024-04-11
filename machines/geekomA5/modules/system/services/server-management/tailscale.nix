{ config, pkgs-unstable, ... }:
let
  tailscaleMachineIp = "100.109.85.80";
in
{
  services = {
    dnsmasq = {
      enable = true;
      resolveLocalQueries = false;

      settings = {
        interface = config.services.tailscale.interfaceName;
        except-interface = "lo";
        address = "/${config.custom.networking.domain}/${tailscaleMachineIp}";
        bind-interfaces = true;
      };
    };

    tailscale = {
      enable = true;
      package = pkgs-unstable.tailscale;
      authKeyFile = config.age.secrets.tailscale_key_geekom.path;

      extraUpFlags = [ "--accept-dns" ];
    };
  };
}
