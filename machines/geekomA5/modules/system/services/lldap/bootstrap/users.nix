{
  config,
  pkgs,
  ...
}:
let
  jsonFormat = pkgs.formats.json { };

  mkUserFromSops = user: {
    id = config.sops.placeholder."lldap/users/${user}/username";
    displayName = config.sops.placeholder."lldap/users/${user}/displayname";
    email = config.sops.placeholder."lldap/users/${user}/email";
    password = config.sops.placeholder."lldap/users/${user}/password";
  };
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
      file = jsonFormat.generate "lldap-user-1-template.json" (mkUserFromSops "user_1") // {
        groups = [ "Admins" ];
      };
    };

    "lldap/bootstrap/users/service_jksv.json" = {
      owner = config.users.users.lldap.name;
      group = config.users.users.lldap.group;
      restartUnits = [
        config.systemd.services.lldap.name
      ];

      path = "/var/lib/lldap/bootstrap/users/jksv.json";
      file = jsonFormat.generate "lldap-jksv-template.json" (mkUserFromSops "jksv") // {
        groups = [ "Service" ];
      };
    };
  };
}
