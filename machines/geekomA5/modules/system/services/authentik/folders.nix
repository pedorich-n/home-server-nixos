{ lib, tmpfilesLib, ... }:
let
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
    "90-authentik-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
    "91-authentik-set" = tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions;
  };
}
