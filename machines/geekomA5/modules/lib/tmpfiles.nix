{ config, lib, ... }:
{
  _module.args.tmpfilesLib = rec {
    mkDefaultTmpFile = argument: {
      user = config.users.users.user.name;
      group = config.users.users.user.group;
      mode = "0644";
      inherit argument;
    };

    mkDefaultTmpDirectory = argument: {
      user = config.users.users.user.name;
      group = config.users.users.user.group;
      mode = "0755";
      inherit argument;
    };

    defaultCreateDirectoryRule = {
      "d" = mkDefaultTmpDirectory ""; # Create a directory
    };

    defaultSetPermissionsRule = {
      "Z" = mkDefaultTmpDirectory ""; # Set mode/permissions recursively to a directory, in case it already exists
    };

    createFoldersUsingDefaultRule = folders: lib.foldl' (acc: folder: acc // { "${folder}" = defaultCreateDirectoryRule; }) { } folders;
    setPermissionsUsingDefaultRule = folders: lib.foldl' (acc: folder: acc // { "${folder}" = defaultSetPermissionsRule; }) { } folders;
  };
}
