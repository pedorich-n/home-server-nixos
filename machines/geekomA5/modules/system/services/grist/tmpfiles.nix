{ lib, tmpfilesLib, ... }:
let
  storeRoot = "/mnt/store/grist";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "persist"
  ];

  foldersToSetPermissions = [
    storeRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-grist-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
    "91-grist-set" = tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions;
  };
}
