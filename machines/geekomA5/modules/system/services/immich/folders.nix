{ config, lib, ... }:
let
  storeRoot = "/mnt/store/immich";
  externalRoot = "/mnt/external/immich-library";

  defaultRules = {
    user = config.users.users.user.name;
    group = config.users.users.user.group;
    mode = "0755";
  };

  mkCreateDirectoryRule = {
    "d" = defaultRules; # Create a directory
  };

  mkSetPermissionsRule = {
    "Z" = defaultRules; # Set mode/permissions recursively to a directory, in case it already exists
  };

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
    "90-immich-create" = lib.foldl' (acc: folder: acc // { ${folder} = mkCreateDirectoryRule; }) { } foldersToCreate;
    "91-immich-set" = lib.foldl' (acc: folder: acc // { ${folder} = mkSetPermissionsRule; }) { } foldersToSetPermissions;
  };
}
