{
  config,
  pkgs-unstable,
  networkingLib,
  systemdLib,
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

  users.users.copyparty.extraGroups = [
    "media"
  ];

  systemd.services.copyparty = {
    unitConfig = systemdLib.requiresAfter [ "zfs.target" ];
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
        idp-h-usr = "X-authentik-username"; # Reverse proxy header for username
        idp-h-grp = "X-authentik-groups"; # Reverse proxy header for groups
        idp-store = "0"; # Do not store users/groups from IdP in the DB

        hist = "/var/lib/copyparty/history"; # Cache location

        gid = config.users.groups.media.gid; # GID for upload/create/mkdir operations
      };

      volumes = {
        "/" = {
          path = root;
          access = {
            "r" = "*";
          };
        };

        "/share" = {
          path = "${root}/share";
          access = {
            "r" = "*";
            "w" = "@acct";
            "d" = "@acct";
            "a" = "@ServerAdmins";
          };
        };
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers.copyparty-secure = {
        entryPoints = [ "web-secure" ];
        rule = "Host(`${networkingLib.mkDomain "copyparty"}`)";
        service = "copyparty-secure";
        middlewares = [ "authentik-secure@docker" ];
      };

      services.copyparty-secure = {
        loadBalancer.servers = [ { url = "http://localhost:${portsCfg.tcp.copyparty-web.portStr}"; } ];
      };
    };
  };
}
