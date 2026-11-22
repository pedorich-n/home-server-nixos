{
  config,
  networkingLib,
  pkgs-unstable,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.radicale;
  lldapPortsCfg = config.custom.networking.ports.tcp.lldap-ldaps;

  storageRoot = "/mnt/store/radicale";

  ldapBase = config.services.lldap.settings.ldap_base_dn;
in
{
  custom = {
    networking.ports.tcp.radicale = {
      port = 32000;
      openFirewall = false;
    };

    services.caddy.hosts.radicale = {
      upstream = "http://127.0.0.1:${portsCfg.portStr}";

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
      server.hosts = [ "127.0.0.1:${portsCfg.portStr}" ];

      auth = {
        type = "ldap";
        ldap_uri = "ldaps://${networkingLib.mkLocalDomain "lldap"}:${lldapPortsCfg.portStr}";
        ldap_base = ldapBase;
        ldap_reader_dn = "UID=radicale,OU=people,${ldapBase}";
        ldap_secret_file = "/run/credentials/${config.systemd.services.radicale.name}/ldap_secret";
        ldap_filter = "(uid={0})";
      };

      storage = {
        filesystem_folder = "${storageRoot}/collections";
        strict_preconditions = true;
      };
    };
  };

  systemd.services.radicale.serviceConfig = {
    LoadCredential = "ldap_secret:${config.sops.secrets."lldap/users/radicale/password".path}";
  };
}
