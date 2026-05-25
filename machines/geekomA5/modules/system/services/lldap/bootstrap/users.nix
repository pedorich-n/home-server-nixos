{
  config,
  autheliaLib,
  pkgs,
  ...
}:
let
  mkUserFromSops =
    {
      user,
      extraArgs ? { },
    }:
    {
      id = config.sops.placeholder."lldap/users/${user}/username";
      displayName = config.sops.placeholder."lldap/users/${user}/displayname" or null;
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
      file = pkgs.writers.writeJSON "lldap-user-authelia-template.json" (mkUserFromSops {
        user = "authelia";
        extraArgs = {
          groups = [
            "lldap_admin"
          ];
        };
      });
    };

    "lldap/bootstrap/users/jellyfin.json" = {
      owner = config.users.users.lldap.name;
      group = config.users.users.lldap.group;
      restartUnits = [
        config.systemd.services.lldap.name
      ];

      path = "/var/lib/lldap/bootstrap/users/jellyfin.json";
      file = pkgs.writers.writeJSON "lldap-user-jellyfin-template.json" (mkUserFromSops {
        user = "jellyfin";
        extraArgs = {
          groups = [
            "lldap_strict_readonly"
          ];
        };
      });
    };

    "lldap/bootstrap/users/user_1.json" = {
      owner = config.users.users.lldap.name;
      group = config.users.users.lldap.group;
      restartUnits = [
        config.systemd.services.lldap.name
      ];

      path = "/var/lib/lldap/bootstrap/users/user_1.json";
      file = pkgs.writers.writeJSON "lldap-user-1-template.json" (mkUserFromSops {
        user = "user_1";
        extraArgs = {
          groups = [
            autheliaLib.groups.Admins
            autheliaLib.groups.Users
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
      file = pkgs.writers.writeJSON "lldap-jksv-template.json" (mkUserFromSops {
        user = "jksv";
        extraArgs = {
          groups = [
            autheliaLib.groups.Service
          ];
        };
      });
    };
  };
}
