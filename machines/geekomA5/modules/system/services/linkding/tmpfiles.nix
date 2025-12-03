{ lib, tmpfilesLib, ... }:
let
  storeRoot = "/mnt/store/linkding";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "data"
  ];

  foldersToSetPermissions = [
    storeRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-linkding-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
    "91-linkding-set" = tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions;
  };
}
