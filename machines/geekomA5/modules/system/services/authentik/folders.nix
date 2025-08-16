{ lib, tmpfilesLib, ... }:
let
  storeRoot = "/mnt/store/authentik";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "media"

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
