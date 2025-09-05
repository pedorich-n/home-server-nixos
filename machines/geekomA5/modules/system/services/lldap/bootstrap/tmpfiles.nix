{
  config,
  lib,
  tmpfilesLib,
  ...
}:
let
  root = "/var/lib/lldap/bootstrap";

  rule = {
    user = config.users.users.lldap.name;
    group = config.users.users.lldap.group;
    mode = "0750";
  };

  foldersToCreate = [
    "${root}/users"
    "${root}/groups"
  ];

  foldersToSet = [ root ];
in
{
  systemd.tmpfiles.settings = {
    "90-lldap-create" = lib.mkMerge [
      (tmpfilesLib.applyRuleToFolders { "d" = rule; } foldersToCreate)
      {
        "${root}/groups/admins.json" = {
          "L+" = rule // {
            argument = "${./groups/admins.json}";
          };
        };
      }
    ];

    "91-lldap-set" = tmpfilesLib.applyRuleToFolders { "Z" = rule; } foldersToSet;
  };
}
