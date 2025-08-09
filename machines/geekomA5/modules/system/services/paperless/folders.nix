{ config, lib, ... }:
let
  storeRoot = "/mnt/store/paperless";
  externalRoot = "/mnt/external/paperless-library";

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

  foldersToCreate =
    (lib.map (folder: "${storeRoot}/${folder}") [
      "data"

      "export"

      "postgresql"

      "redis"
    ])
    ++ (lib.map (folder: "${externalRoot}/${folder}") [
      "media"
    ]);

  foldersToSetPermissions = [
    storeRoot
    externalRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-paperless-create" = lib.foldl' (acc: folder: acc // { ${folder} = mkCreateDirectoryRule; }) { } foldersToCreate;
    "91-paperless-set" = lib.foldl' (acc: folder: acc // { ${folder} = mkSetPermissionsRule; }) { } foldersToSetPermissions;
  };
}
