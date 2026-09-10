{
  lib,
  tmpfilesLib,
  ...
}:
let
  storeRoot = "/mnt/store/valheim-server";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "config"
    "data"
  ];

  foldersToSetPermissions = [
    storeRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-valheim-server-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
    "91-valheim-server-set" = tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions;
  };
}
