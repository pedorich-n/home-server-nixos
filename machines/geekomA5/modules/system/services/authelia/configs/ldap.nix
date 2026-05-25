{
  config,
  networkingLib,
  pkgs,
  ...
}:
let
  baseDN = config.services.lldap.settings.ldap_base_dn;
in
{

  sops.templates."authelia/ldap.yaml" = {
    owner = config.services.authelia.instances.main.user;
    group = config.services.authelia.instances.main.group;
    restartUnits = [
      config.systemd.services.authelia-main.name
    ];

    file = pkgs.writers.writeYAML "authelia-ldap-template.yaml" {
      authentication_backend = {
        refresh_interval = "5m";

        ldap = {
          implementation = "lldap";
          address = "ldaps://${networkingLib.mkDomain "lldap"}:${config.custom.networking.ports.tcp.lldap-ldaps.portStr}";
          base_dn = baseDN;
          user = "UID=${config.sops.placeholder."lldap/users/authelia/username"},OU=people,${baseDN}";
          password = config.sops.placeholder."lldap/users/authelia/password";

          pooling = {
            enable = true;
            count = 5;
          };

          attributes = {
            extra = {
              sshpubkey = {
                name = "ssh_public_key";
                multi_valued = true;
                value_type = "string";
              };
            };
          };
        };
      };
    };

  };
}
