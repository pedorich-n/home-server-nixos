{
  config,
  lib,
  tmpfilesLib,
  ...
}:
let
  storeRoot = config.custom.manual-backup.root;

  rule = {
    user = config.custom.manual-backup.owner.user;
    group = config.custom.manual-backup.owner.group;
    mode = "0775";
  };

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "android"
    "android/apps"
  ];

  foldersToSetPermissions = [
    storeRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-manual-backup-create" = tmpfilesLib.applyRuleToFolders { "d" = rule; } foldersToCreate;
    "91-manual-backup-set" = tmpfilesLib.applyRuleToFolders { "Z" = rule; } foldersToSetPermissions;
  };
}
