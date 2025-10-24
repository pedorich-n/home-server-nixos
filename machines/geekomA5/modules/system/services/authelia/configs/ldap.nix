{
  config,
  pkgs,
  ...
}:
let
  yamlFormat = pkgs.formats.yaml { };
in
{

  sops.templates."authelia/ldap.yaml" = {
    owner = config.services.authelia.instances.main.user;
    group = config.services.authelia.instances.main.group;
    restartUnits = [
      config.systemd.services.authelia-main.name
    ];

    file = yamlFormat.generate "authelia-ldap-template.yaml" {
      authentication_backend = {
        refresh_interval = "5m";

        ldap = {
          implementation = "lldap";
          address = "ldap://127.0.0.1:${config.custom.networking.ports.tcp.lldap-ldap.portStr}";
          base_dn = "DC=server";
          user = "UID=authelia,OU=people,DC=server";
          password = config.sops.placeholder."authelia/ldap/password";

          # Disabled because of https://github.com/authelia/authelia/issues/9936
          pooling = {
            enable = true;
            count = 5;
          };
        };
      };
    };

  };
}
