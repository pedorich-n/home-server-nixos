{ lib, tmpfilesLib, ... }:
let
  storeRoot = "/mnt/store/core-keeper-servers";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "underground-monkeys/server-data"
    "underground-monkeys/server-files"
  ];

  foldersToSetPermissions = [
    storeRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-core-keeper-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
    "91-core-keeper-set" = tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions;
  };
}
