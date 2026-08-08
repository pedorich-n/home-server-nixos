{
  lib,
  tmpfilesLib,
  ...
}:
let
  storeRoot = "/mnt/store/safebucket";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "notifications"
    "activity"
    "db"
  ];

  foldersToSetPermissions = [
    storeRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-safebucket-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
    "91-safebucket-set" = tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions;
  };
}
