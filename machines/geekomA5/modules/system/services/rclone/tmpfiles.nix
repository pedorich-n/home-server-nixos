{
  config,
  lib,
  tmpfilesLib,
  ...
}:
let
  root = "/mnt/rclone";

  folders = lib.map (folder: "${root}/${folder}") [
    "mega"
  ];

  rule = {
    user = config.users.users.rclone.name;
    group = config.users.groups.media.name;
    mode = "0755";
  };
in
{
  systemd.tmpfiles.settings = {
    "90-rclone-create" = tmpfilesLib.applyRuleToFolders { "d" = rule; } folders;
  };
}
