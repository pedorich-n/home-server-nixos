{
  config,
  pkgs,
  ...
}:
let
  iniFormat = pkgs.formats.ini { };
in
{
  sops.templates = {
    "couchdb/admin.ini" = {
      owner = config.services.couchdb.user;
      group = config.services.couchdb.group;
      restartUnits = [
        config.systemd.services.couchdb.name
      ];
      file = iniFormat.generate "couchdb-admin.ini" {
        admins = {
          admin = config.sops.placeholder."couchdb/users/admin/password";
        };
      };
    };
  };
}
