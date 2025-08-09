{ lib, tmpfilesLib, ... }:
let
  storeRoot = "/mnt/store/ente";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "museum"
    "museum/data"

    "postgresql"
  ];

  foldersToSetPermissions = [
    storeRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-ente-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
    "91-ente-set" = tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions;
  };
}
