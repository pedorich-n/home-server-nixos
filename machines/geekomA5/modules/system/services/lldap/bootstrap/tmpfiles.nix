{
  config,
  lib,
  tmpfilesLib,
  pkgs,
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
    "${root}/user-schemas"
  ];

  foldersToSet = [ root ];

  groupFiles = pkgs.callPackage ./_groups.nix { };
  schemaFile = pkgs.callPackage ./_user-schemas.nix { };
in
{
  systemd.tmpfiles.settings = {
    "90-lldap-create" = lib.mkMerge [
      (tmpfilesLib.applyRuleToFolders { "d" = rule; } foldersToCreate)
      {
        "${root}/groups" = {
          "L+" = rule // {
            argument = "${groupFiles}";
          };
        };
        "${root}/user-schemas/schemas.json" = {
          "L+" = rule // {
            argument = "${schemaFile}";
          };
        };
      }
    ];

    "91-lldap-set" = tmpfilesLib.applyRuleToFolders { "Z" = rule; } foldersToSet;
  };
}
