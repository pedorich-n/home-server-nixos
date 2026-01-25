{
  config,
  lib,
  tmpfilesLib,
  ...
}:
let
  storeRoot = "/mnt/store/mail";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "archive"
  ];

  foldersToSetPermissions = [
    storeRoot
  ];

  rule = {
    group = config.users.groups.mail.name;
    mode = "0770";
  };
in
{
  systemd.tmpfiles.settings = {
    "90-mail-create" = tmpfilesLib.applyRuleToFolders { "d" = rule; } foldersToCreate;
    "91-mail-set" = tmpfilesLib.applyRuleToFolders { "Z" = rule; } foldersToSetPermissions;
  };
}
