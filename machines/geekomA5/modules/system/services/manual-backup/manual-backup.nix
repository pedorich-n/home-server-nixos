{ config, lib, ... }:
{
  options.custom.manual-backup = {
    root = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/store/manual-backup";
      readOnly = true;
    };

    owner = {
      user = lib.mkOption {
        type = lib.types.str;
        default = config.users.users.user.name;
        readOnly = true;
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = config.users.users.user.group;
        readOnly = true;
      };
    };
  };
}
