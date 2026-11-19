{
  config,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.anki-sync-server;

  privateState = "/var/lib/private/anki-sync-server";
in
{
  custom = {
    networking.ports.tcp.anki-sync-server = {
      port = 33300;
      openFirewall = false;
    };

    services.caddy.hosts.anki-sync = {
      upstream = "http://127.0.0.1:${portsCfg.portStr}";
    };
  };

  systemd = {
    # Similar to how Prowlarr does it: https://github.com/NixOS/nixpkgs/blob/c1a2b9132d6a9d870410ac642df7129abfa938e3/nixos/modules/services/misc/servarr/prowlarr.nix#L66-L71
    mounts = [
      {
        what = "/mnt/store/anki-sync-server";
        where = privateState;
        options = "bind";
      }
    ];

    services.anki-sync-server = {
      unitConfig.RequiresMountsFor = [
        privateState
      ];

      serviceConfig.StateDirectoryMode = "0750";
    };
  };

  services.anki-sync-server = {
    enable = true;

    address = "127.0.0.1";
    inherit (portsCfg) port;

    users = [
      {
        username = "user_1";
        passwordFile = config.sops.secrets."anki-sync-server/users/user_1/password".path;
      }
    ];
  };
}
