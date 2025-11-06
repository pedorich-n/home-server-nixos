{ lib, tmpfilesLib, ... }:
let
  storeRoot = "/mnt/store/librechat";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "mongodb"

    "postgresql"

    "server"
    "server/images"
    "server/uploads"
    "server/logs"
  ];

  foldersToSetPermissions = [
    storeRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-librechat-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
    "91-librechat-set" = tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions;
  };
}
