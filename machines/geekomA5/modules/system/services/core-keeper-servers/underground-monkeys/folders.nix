{ config, lib, ... }:
let
  storeRoot = "/mnt/store/core-keeper-servers";

  defaultRules = {
    user = config.users.users.user.name;
    group = config.users.users.user.group;
    mode = "0700";
  };

  mkCreateDirectoryRule = {
    "d" = defaultRules; # Create a directory
  };

  mkSetPermissionsRule = {
    "Z" = defaultRules; # Set mode/permissions recursively to a directory, in case it already exists
  };

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
    "90-core-keeper-create" = lib.foldl' (acc: folder: acc // { ${folder} = mkCreateDirectoryRule; }) { } foldersToCreate;
    "91-core-keeper-set" = lib.foldl' (acc: folder: acc // { ${folder} = mkSetPermissionsRule; }) { } foldersToSetPermissions;
  };
}
