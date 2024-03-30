{ config, pkgs-unstable, ... }:
let
  tailscaleMachineIp = "100.99.63.71";
in
{
  services = {
    dnsmasq = {
      enable = true;
      settings = {
        interface = config.services.tailscale.interfaceName;
        address = "/server.local/${tailscaleMachineIp}";
        bind-interfaces = true;
      };
    };

    tailscale = {
      enable = true;
      package = pkgs-unstable.tailscale;
      authKeyFile = config.age.secrets.tailscale-key.path;

      extraUpFlags = [ "--accept-dns" ];
    };
  };
}
