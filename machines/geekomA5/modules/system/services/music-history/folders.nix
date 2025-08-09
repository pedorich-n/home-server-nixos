{ lib, tmpfilesLib, ... }:
let
  storeRoot = "/mnt/store/music-history";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "maloja"
    "maloja/data"

    "multi-scrobbler"
    "multi-scrobbler/config"
  ];

  foldersToSetPermissions = [
    storeRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-music-history-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
    "91-music-history-set" = tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions;
  };
}
