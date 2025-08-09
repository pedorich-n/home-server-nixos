{ lib, tmpfilesLib, ... }:
let
  inherit (tmpfilesLib) mkDefaultCreateDirectoryRule mkDefaultSetPermissionsRule;

  storeRoot = "/mnt/store/core-keeper-servers";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "underground-monkeys"
    "underground-monkeys/server-data"
    "underground-monkeys/server-files"
  ];

  foldersToSetPermissions = [
    storeRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-core-keeper-create" = lib.foldl' (acc: folder: acc // { ${folder} = mkDefaultCreateDirectoryRule; }) { } foldersToCreate;
    "91-core-keeper-set" = lib.foldl' (acc: folder: acc // { ${folder} = mkDefaultSetPermissionsRule; }) { } foldersToSetPermissions;
  };
}
