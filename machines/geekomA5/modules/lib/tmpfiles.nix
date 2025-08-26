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

    mkDefaultMediaTmpDirectory = argument: {
      user = config.users.users.user.name;
      group = config.users.groups.media.name;
      mode = "0775";
      inherit argument;
    };

    applyRuleToFolders = rule: folders: lib.foldl' (acc: folder: acc // { "${folder}" = rule; }) { } folders;

    #LINK - See https://www.freedesktop.org/software/systemd/man/tmpfiles.d.html

    createFoldersUsingDefaultRule = folders: applyRuleToFolders { "d" = mkDefaultTmpDirectory ""; } folders;
    setPermissionsUsingDefaultRule = folders: applyRuleToFolders { "Z" = mkDefaultTmpDirectory ""; } folders;

    createFoldersUsingDefaultMediaRule = folders: applyRuleToFolders { "d" = mkDefaultMediaTmpDirectory ""; } folders;
    setPermissionsUsingDefaultMediaRule = folders: applyRuleToFolders { "Z" = mkDefaultMediaTmpDirectory ""; } folders;
  };
}
