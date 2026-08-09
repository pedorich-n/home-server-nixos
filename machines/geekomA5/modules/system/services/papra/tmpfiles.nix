{
  config,
  lib,
  tmpfilesLib,
  ...
}:
let
  storeRoot = "/mnt/store/papra";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "data"
  ];

  foldersToSetPermissions = [
    storeRoot
  ];

  rule = {
    user = config.services.papra.user;
    group = config.services.papra.group;
    mode = "0750";
  };
in
{
  systemd.tmpfiles.settings = {
    "90-papra-create" = tmpfilesLib.applyRuleToFolders { "d" = rule; } foldersToCreate;
    "91-papra-set" = tmpfilesLib.applyRuleToFolders { "Z" = rule; } foldersToSetPermissions;
  };
}
