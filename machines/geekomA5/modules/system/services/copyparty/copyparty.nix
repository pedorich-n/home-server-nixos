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
        config.users.groups.media.gid
      ];
      UMask = lib.mkForce "002"; # rwx rwx r-x
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

        gid = config.users.groups.media.gid; # GID for upload/create/mkdir operations
        chmod-d = "775"; # Permissions for created directories
        chmod-f = "664"; # Permissions for created files
      };

      volumes = {
        "/" = {
          path = root;
          access = {
            # Read: all logged in users can read
            "r" = "@acct";
            # Write, Delete, Admin: only users in the Admins group
            "wda" = "@Admins";
          };
        };

        "/share" = {
          path = "${root}/share";
          access = {
            # Read: all logged in users can read
            "r" = "*";
            # Write, Delete, Admin: only users in the Service group
            "wd" = "@acct";
            # Admin: only users in the Admins group
            "a" = "@Admins";
          };
        };

        "/switch-saves" = {
          path = "/mnt/store/manual-backup/switch/saves/jksv";
          access = {
            # Read: all logged in users can read
            "r" = "@acct";
            # Write, Delete: only users in the Admins, Service groups
            "wd" = [
              "@Admins"
              "@Service"
            ];
            # Admin: only users in the Admins group
            "a" = "@Admins";
          };
        };
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers.copyparty-secure = {
        entryPoints = [ "web-secure" ];
        rule = "Host(`${networkingLib.mkDomain "copyparty"}`)";
        service = "copyparty-secure";
        middlewares = [ "authelia-basic@file" ];
      };

      services.copyparty-secure = {
        loadBalancer.servers = [ { url = "http://localhost:${portsCfg.tcp.copyparty-web.portStr}"; } ];
      };
    };
  };
}
