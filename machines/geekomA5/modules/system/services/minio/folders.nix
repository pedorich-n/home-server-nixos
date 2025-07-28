{ config, ... }:
let

  globalRule = {
    user = config.users.users.minio.name;
    group = config.users.users.minio.group;
    mode = "0755";
  };
in
{
  systemd.tmpfiles.settings."90-minio" = {
    "/mnt/external/object-storage/minio" = {
      "d" = globalRule; # Create a directory
      "z" = globalRule; # Set mode/permissions to a directory, in case it already exists
    };
  };
}
