{ lib, tmpfilesLib, ... }:
let
  inherit (tmpfilesLib) mkDefaultCreateDirectoryRule mkDefaultSetPermissionsRule;

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
    "90-grist-create" = lib.foldl' (acc: folder: acc // { ${folder} = mkDefaultCreateDirectoryRule; }) { } foldersToCreate;
    "91-grist-set" = lib.foldl' (acc: folder: acc // { ${folder} = mkDefaultSetPermissionsRule; }) { } foldersToSetPermissions;
  };
}
