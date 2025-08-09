{ config, lib, ... }:
let
  storeRoot = "/mnt/store/server-management/authentik";

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
    "90-authentik-create" = lib.foldl' (acc: folder: acc // { ${folder} = mkCreateDirectoryRule; }) { } foldersToCreate;

    "91-authentik-set" = lib.foldl' (acc: folder: acc // { ${folder} = mkSetPermissionsRule; }) { } foldersToSetPermissions;
  };
}
