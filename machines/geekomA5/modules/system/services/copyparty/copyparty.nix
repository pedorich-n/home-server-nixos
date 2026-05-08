{
  config,
  pkgs-unstable,
  systemdLib,
  lib,
  ...
}:
let
  root = "/mnt/external/data-library";

  socketPath = "/run/copyparty/copyparty.sock";
in
{
  custom.services.caddy.hosts.copyparty = {
    upstream = "unix/${socketPath}";
    auth = "authelia-basic";
  };

  systemd.services.caddy.serviceConfig.SupplementaryGroups = [
    config.services.copyparty.group
  ];

  systemd.services.copyparty = {
    unitConfig = systemdLib.requisiteAfter [
      "zfs.target"
    ];

    serviceConfig = {
      SupplementaryGroups = [
        config.users.groups.media.gid
        config.services.caddy.group
      ];
      UMask = lib.mkForce "002"; # rwx rwx r-x
      RuntimeDirectoryMode = lib.mkForce "0750"; # Default is 0700, but we need caddy to acccess the socket.
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
        i = "unix:660:caddy:${socketPath}"; # Unix socket for Caddy
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
            # Read: all users in the Users group
            "r" = "@Users";
            # Write, Delete, Admin: only users in the Admins group
            "wda" = "@Admins";
          };
        };

        "/share" = {
          path = "${root}/share";
          access = {
            # Read, Write, Delete: all users in the Users group
            "rwd" = "@Users";
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
  };
}
