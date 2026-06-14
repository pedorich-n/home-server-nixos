{
  lib,
  tmpfilesLib,
  ...
}:
let
  storeRoot = "/mnt/store/airtrail";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "postgresql"

    "server"
    "server/uploads"
  ];

  foldersToSetPermissions = [
    storeRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-airtrail-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
    "91-airtrail-set" = tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions;
  };
}
