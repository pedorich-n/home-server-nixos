{ config, ... }:
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

    mkDefaultCreateDirectoryRule = {
      "d" = mkDefaultTmpDirectory ""; # Create a directory
    };

    mkDefaultSetPermissionsRule = {
      "Z" = mkDefaultTmpDirectory ""; # Set mode/permissions recursively to a directory, in case it already exists
    };
  };
}
