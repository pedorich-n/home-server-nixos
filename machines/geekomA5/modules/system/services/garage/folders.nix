{ config, ... }:
let

  globalRule = {
    user = config.users.users.user.name;
    group = config.users.users.user.group;
    mode = "0777";
  };
in
{
  systemd.tmpfiles.settings."90-garage" = {
    "/mnt/external/data-library/storage" = {
      "d" = globalRule; # Create a directory
      "z" = globalRule; # Set mode/permissions to a directory, in case it already exists
    };

    "/mnt/external/data-library/storage/data" = {
      "d" = globalRule; # Create a directory
      "z" = globalRule; # Set mode/permissions to a directory, in case it already exists
    };
  };
}
