{
  config,
  lib,
  networkingLib,
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
in
{
  custom.networking.ports.tcp = {
    lldap-ldap = {
      port = 3890;
      openFirewall = false;
    };

    lldap-http = {
      port = 17170;
      openFirewall = false;
    };
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

      ExecStartPost = "-${lib.getExe bootstrap}";
    };
  };

  services = {
    traefik.dynamicConfigOptions.http = {
      routers.lldap-secure = {
        entryPoints = [ "web-secure" ];
        rule = "Host(`${networkingLib.mkDomain "lldap"}`)";
        service = "lldap-secure";
      };

      services.lldap-secure = {
        loadBalancer.servers = [ { url = "http://127.0.0.1:${portsCfg.lldap-http.portStr}"; } ];
      };
    };

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

        ldap_base_dn = "DC=server";

        database_url = "sqlite:///var/lib/lldap/users.db?mode=rwc";
        key_file = ""; # I am using key seed, so there's no need for a file
      };
    };
  };
}
