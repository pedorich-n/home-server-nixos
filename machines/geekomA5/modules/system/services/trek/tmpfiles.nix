{
  lib,
  tmpfilesLib,
  ...
}:
let
  storeRoot = "/mnt/store/trek";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "data"

    "uploads"
  ];

  foldersToSetPermissions = [
    storeRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-trek-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
    "91-trek-set" = tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions;
  };
}
