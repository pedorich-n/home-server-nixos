{ lib, tmpfilesLib, ... }:
let
  storeRoot = "/mnt/store/gitea-mirror";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "data"
  ];

  foldersToSetPermissions = [
    storeRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-gitea-mirror-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
    "91-gitea-mirror-set" = tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions;
  };
}
