{ config, tmpfilesLib, ... }:
let

  globalRule = {
    user = config.users.users.minio.name;
    group = config.users.users.minio.group;
    mode = "0755";
  };

  folders = [
    "/mnt/external/object-storage/minio"
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-minio-create" = tmpfilesLib.applyRuleToFolders { "d" = globalRule; } folders;
    "91-minio-set" = tmpfilesLib.applyRuleToFolders { "Z" = globalRule; } folders;
  };
}
