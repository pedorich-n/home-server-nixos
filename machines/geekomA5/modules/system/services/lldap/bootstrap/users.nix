{
  config,
  pkgs,
  ...
}:
let
  jsonFormat = pkgs.formats.json { };

  mkUserFromSops =
    {
      user,
      extraArgs ? { },
    }:
    {
      id = config.sops.placeholder."lldap/users/${user}/username";
      displayName = config.sops.placeholder."lldap/users/${user}/displayname";
      email = config.sops.placeholder."lldap/users/${user}/email";
      password = config.sops.placeholder."lldap/users/${user}/password";
    }
    // extraArgs;
in
{

  sops.templates = {
    "lldap/bootstrap/users/authelia.json" = {
      owner = config.users.users.lldap.name;
      group = config.users.users.lldap.group;
      restartUnits = [
        config.systemd.services.lldap.name
      ];

      path = "/var/lib/lldap/bootstrap/users/authelia.json";
      file = jsonFormat.generate "lldap-user-authelia-template.json" {
        id = "authelia";
        email = "authelia@server.lan";
        password = config.sops.placeholder."lldap/users/authelia/password";
        groups = [ "lldap_admin" ];
      };
    };

    "lldap/bootstrap/users/user_1.json" = {
      owner = config.users.users.lldap.name;
      group = config.users.users.lldap.group;
      restartUnits = [
        config.systemd.services.lldap.name
      ];

      path = "/var/lib/lldap/bootstrap/users/user_1.json";
      file = jsonFormat.generate "lldap-user-1-template.json" (mkUserFromSops {
        user = "user_1";
        extraArgs = {
          groups = [
            "Admins"
            "Users"
          ];
        };
      });
    };

    "lldap/bootstrap/users/service_jksv.json" = {
      owner = config.users.users.lldap.name;
      group = config.users.users.lldap.group;
      restartUnits = [
        config.systemd.services.lldap.name
      ];

      path = "/var/lib/lldap/bootstrap/users/jksv.json";
      file = jsonFormat.generate "lldap-jksv-template.json" (mkUserFromSops {
        user = "jksv";
        extraArgs = {
          groups = [ "Service" ];
        };
      });
    };
  };
}
