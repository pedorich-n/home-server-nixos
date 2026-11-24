{
  autheliaLib,
  config,
  networkingLib,
  pkgs-unstable,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp;

  ldapBase = config.services.lldap.settings.ldap_base_dn;

  storageRoot = "/mnt/store/radicale";
  credentialsDir = "/run/credentials/${config.systemd.services.radicale.name}";
in
{
  custom = {
    networking.ports.tcp.radicale = {
      port = 32000;
      openFirewall = false;
    };

    services.caddy.hosts.radicale = {
      upstream = "http://127.0.0.1:${portsCfg.radicale.portStr}";

      extraConfig = ''
        redir /.well-known/caldav / permanent
        redir /.well-known/carddav / permanent
      '';
    };
  };

  services.radicale = {
    enable = true;

    package = pkgs-unstable.radicale;

    settings = {
      server.hosts = [ "127.0.0.1:${portsCfg.radicale.portStr}" ];
      auth = {
        type = "ldap";
        ldap_uri = "ldaps://${networkingLib.mkLocalDomain "lldap"}:${portsCfg.lldap-ldaps.portStr}";
        ldap_base = "ou=people,${ldapBase}";
        ldap_reader_dn = "UID=radicale,OU=people,${ldapBase}";
        ldap_secret_file = "${credentialsDir}/ldap_secret";
        ldap_filter = "(&(uid={0})(|(memberOf=cn=${autheliaLib.groups.Users},ou=groups,${ldapBase})(memberOf=cn=${autheliaLib.groups.Admins},ou=groups,${ldapBase})(memberOf=cn=${autheliaLib.groups.Service},ou=groups,${ldapBase})))";
        ldap_groups_attribute = "memberOf";
      };

      sharing = {
        type = "csv";
        database_path = "${credentialsDir}/sharing_csv";
        collection_by_map = true;
      };

      storage = {
        filesystem_folder = "${storageRoot}/collections";
        strict_preconditions = true;
      };
    };

    rights = {
      "00-admin" = {
        groups = autheliaLib.groups.Admins;
        collection = ".+";
        permissions = "RrWw";
      };

      # `R` on the root collection is what makes principal discovery work:
      # /.well-known/caldav -> / -> /{user}/.
      "10-root" = {
        user = ".+";
        collection = "";
        permissions = "R";
      };

      "20-principal" = {
        user = ".+";
        collection = "{user}";
        permissions = "RW";
      };

      "30-collections" = {
        user = ".+";
        collection = "{user}/[^/]+";
        permissions = "rw";
      };
    };
  };

  systemd.services.radicale.serviceConfig = {
    LoadCredential = [
      "ldap_secret:${config.sops.secrets."lldap/users/radicale/password".path}"
      "sharing_csv:${config.sops.templates."radicale/sharing.csv".path}"
    ];
  };
}
