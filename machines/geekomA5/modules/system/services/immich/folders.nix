{ lib, tmpfilesLib, ... }:
let
  inherit (tmpfilesLib) mkDefaultCreateDirectoryRule mkDefaultSetPermissionsRule;

  storeRoot = "/mnt/store/immich";
  externalRoot = "/mnt/external/immich-library";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "cache"
    "cache/thumbnails"
    "cache/profile"
    "cache/machine-learning"

    # "machine-learning"
    # "machine-learning/.cache"
    # "machine-learning/.config"

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
    "90-immich-create" = lib.foldl' (acc: folder: acc // { ${folder} = mkDefaultCreateDirectoryRule; }) { } foldersToCreate;
    "91-immich-set" = lib.foldl' (acc: folder: acc // { ${folder} = mkDefaultSetPermissionsRule; }) { } foldersToSetPermissions;
  };
}
