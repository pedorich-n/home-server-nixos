{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp;

  bootstrap = pkgs.callPackage ./bootstrap/_bootstrap.nix {
    lldapHttpPort = portsCfg.lldap-http.portStr;
    lldapAdminPasswordFile = config.sops.secrets."lldap/users/admin/password".path;
  };

  certCfg = config.security.acme.certs.local;
in
{
  custom.networking.ports.tcp = {
    lldap-ldap = {
      port = 3890;
      openFirewall = false;
    };

    lldap-ldaps = {
      port = 636;
      openFirewall = true;
    };

    lldap-http = {
      port = 32200;
      openFirewall = false;
    };
  };

  custom.services.caddy.hosts.lldap = {
    upstream = "http://127.0.0.1:${portsCfg.lldap-http.portStr}";
  };

  users = {
    users.lldap = {
      isSystemUser = true;
      group = "lldap";
    };

    groups.lldap = { };
  };

  systemd.services.lldap = {
    serviceConfig = {
      DynamicUser = lib.mkForce false;

      # Allow non-root lldap user to bind LDAPS on privileged port <1024.
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];

      # Required for LLDAP to read TLS cert and key for LDAPS
      SupplementaryGroups = [
        certCfg.group
      ];

      ExecStartPost = "-${lib.getExe bootstrap}";
    };
  };

  services = {
    lldap = {
      enable = true;

      package = pkgs-unstable.lldap;

      environment = {
        LLDAP_JWT_SECRET_FILE = config.sops.secrets."lldap/jwt_secret".path;
        LLDAP_KEY_SEED_FILE = config.sops.secrets."lldap/key_seed".path;
        LLDAP_LDAP_USER_PASS_FILE = config.sops.secrets."lldap/users/admin/password".path;
      };

      settings = {
        ldap_port = portsCfg.lldap-ldap.port;
        http_port = portsCfg.lldap-http.port;

        ldap_user_email = "admin@server.lan";
        ldap_user_dn = "admin";
        force_ldap_user_pass_reset = "always";

        ldap_base_dn = "DC=server";

        database_url = "sqlite:///var/lib/lldap/users.db?mode=rwc";
        key_file = ""; # I am using key seed, so there's no need for a file

        ldaps_options = {
          enabled = true;
          port = portsCfg.lldap-ldaps.port;
          cert_file = "${certCfg.directory}/cert.pem";
          key_file = "${certCfg.directory}/key.pem";
        };
      };
    };
  };
}
