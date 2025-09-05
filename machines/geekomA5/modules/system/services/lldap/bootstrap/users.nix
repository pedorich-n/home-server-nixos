{
  config,
  pkgs,
  ...
}:
let
  jsonFormat = pkgs.formats.json { };
in
{

  sops.templates = {
    "lldap/bootstrap/users/authelia.json" = {
      owner = config.users.users.lldap.name;
      group = config.users.users.lldap.group;

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

      path = "/var/lib/lldap/bootstrap/users/user_1.json";
      file = jsonFormat.generate "lldap-user-1-template.json" {
        id = config.sops.placeholder."lldap/users/user_1/username";
        displayName = config.sops.placeholder."lldap/users/user_1/displayname";
        email = config.sops.placeholder."lldap/users/user_1/email";
        password = config.sops.placeholder."lldap/users/user_1/password";
        groups = [ "Admins" ];
      };
    };
  };
}
