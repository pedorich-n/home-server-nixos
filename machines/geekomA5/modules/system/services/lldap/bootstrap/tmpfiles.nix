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
    # "${root}/groups"
  ];

  foldersToSet = [ root ];

  groupFiles = pkgs.callPackage ./_groups.nix { };
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
      }
    ];

    "91-lldap-set" = tmpfilesLib.applyRuleToFolders { "Z" = rule; } foldersToSet;
  };
}
