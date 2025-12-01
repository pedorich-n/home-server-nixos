{ lib, tmpfilesLib, ... }:
let
  storeRoot = "/mnt/store/searxng";

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
    "90-searxng-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
    "91-searxng-set" = tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions;
  };
}
