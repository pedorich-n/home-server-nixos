{ lib, tmpfilesLib, ... }:
let
  inherit (tmpfilesLib) mkDefaultCreateDirectoryRule mkDefaultSetPermissionsRule;

  storeRoot = "/mnt/store/server-management/authentik";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "media"
    "maloja/data"

    "postgres"

    "redis"
  ];

  foldersToSetPermissions = [
    storeRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-authentik-create" = lib.foldl' (acc: folder: acc // { ${folder} = mkDefaultCreateDirectoryRule; }) { } foldersToCreate;
    "91-authentik-set" = lib.foldl' (acc: folder: acc // { ${folder} = mkDefaultSetPermissionsRule; }) { } foldersToSetPermissions;
  };
}
