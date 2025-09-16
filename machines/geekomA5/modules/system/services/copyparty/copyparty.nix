{
  config,
  pkgs-unstable,
  networkingLib,
  systemdLib,
  lib,
  ...
}:
let
  root = "/mnt/external/data-library";

  portsCfg = config.custom.networking.ports;
in
{
  custom.networking.ports.tcp = {
    copyparty-web = {
      port = 46000;
      openFirewall = false;
    };
  };

  systemd.services.copyparty = {
    unitConfig = systemdLib.requisiteAfter [
      "zfs.target"
    ];

    serviceConfig = {
      SupplementaryGroups = [
        config.users.groups.media.name
      ];
      UMask = lib.mkForce "037"; # rwx r-- ---
    };
  };

  services = {
    copyparty = {
      enable = true;
      package = pkgs-unstable.copyparty.override {
        withZeroMQ = false;
        withFTP = false;
      };

      settings = {
        i = "127.0.0.1"; # Interface to bind to
        p = portsCfg.tcp.copyparty-web.portStr; # Port to listen on
        http-only = true; # Disable TLS, use HTTP only since we are behind a reverse proxy
        no-crt = true; # Disable certificate generation

        rproxy = "1"; # Enable reverse proxy mode
        idp-h-usr = "Remote-User"; # Reverse proxy header for username
        idp-h-grp = "Remote-Groups"; # Reverse proxy header for groups
        idp-store = "0"; # Do not store users/groups from IdP in the DB

        hist = "/var/lib/copyparty/history"; # Cache location
      };

      volumes = {
        "/" = {
          path = root;
          access = {
            "r" = "*";
            "w" = "@Admins";
            "d" = "@Admins";
            "a" = "@Admins";
          };
        };

        "/share" = {
          path = "${root}/share";
          access = {
            "r" = "*";
            "w" = "@acct";
            "d" = "@acct";
            "a" = "@Admins";
          };
          flags = {
            gid = config.users.groups.media.gid; # GID for upload/create/mkdir operations
          };
        };
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers.copyparty-secure = {
        entryPoints = [ "web-secure" ];
        rule = "Host(`${networkingLib.mkDomain "copyparty"}`)";
        service = "copyparty-secure";
        middlewares = [ "authelia@file" ];
      };

      services.copyparty-secure = {
        loadBalancer.servers = [ { url = "http://localhost:${portsCfg.tcp.copyparty-web.portStr}"; } ];
      };
    };
  };
}
