{ config, ... }:
let

  globalRule = {
    user = config.users.users.user.name;
    group = config.users.users.user.group;
    mode = "0755";
  };

  publicRule = {
    user = config.users.users.nobody.name;
    group = config.users.users.nobody.group;
    mode = "0777";
  };
in
{
  systemd.tmpfiles.settings."90-samba" = {
    "/mnt/external/data-library/share" = {
      "d" = globalRule; # Create a directory
      "z" = globalRule; # Set mode/permissions to a directory, in case it already exists
    };

    "/mnt/external/data-library/share/public" = {
      "d" = publicRule; # Create a directory
      "z" = publicRule; # Set mode/permissions to a directory, in case it already exists
    };
  };
}
