{
  config,
  tmpfilesLib,
  ...
}:
let
  externalRoot = "/mnt/external/seaweedfs";
  volumeDataRoot = "${externalRoot}/volumes";

  rule = {
    user = config.users.users.seaweedfs.name;
    group = config.users.groups.seaweedfs.name;
    mode = "0750";
    argument = "";
  };
in
{
  systemd.tmpfiles.settings = {
    # master and filer dirs are managed by StateDirectory in the systemd services
    "90-seaweedfs-create" = tmpfilesLib.applyRuleToFolders { "d" = rule; } [ volumeDataRoot ];
    "91-seaweedfs-set" = tmpfilesLib.applyRuleToFolders { "Z" = rule; } [ externalRoot ];
  };
}
