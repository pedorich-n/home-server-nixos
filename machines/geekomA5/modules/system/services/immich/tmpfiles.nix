{ lib, tmpfilesLib, ... }:
let
  storeRoot = "/mnt/store/immich";
  externalRoot = "/mnt/external/immich-library";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "cache/thumbnails"
    "cache/profile"
    "cache/machine-learning"

    "postgresql"

    "redis"
  ];

  foldersToSetPermissions = [
    storeRoot
    externalRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-immich-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
    "91-immich-set" = tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions;
  };
}
