{
  inputs,
  config,
  pkgs-unstable,
  lib,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.olivetin;
in
{
  disabledModules = [ "services/web-apps/olivetin.nix" ];
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/web-apps/olivetin.nix"
  ];

  warnings = lib.optional (lib.versionAtLeast config.system.nixos.release "26.05") "The updated Olivetin module now available in stable";

  custom = {
    networking.ports.tcp.olivetin = {
      port = 32400;
      openFirewall = false;
    };

    services.caddy.hosts.olivetin = {
      upstream = "http://localhost:${portsCfg.portStr}";
    };
  };

  systemd.services.olivetin = {
    serviceConfig = {
      SupplementaryGroups = [
        config.users.groups.wheel.name
      ];
    };
  };

  services.olivetin = {
    enable = true;
    package = pkgs-unstable.olivetin-3k;

    path = [
      config.systemd.package
    ];

    settings = {
      ListenAddressSingleHTTPFrontend = "127.0.0.1:${portsCfg.portStr}";
    };
  };
}
