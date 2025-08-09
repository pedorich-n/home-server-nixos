{ config, ... }:
{
  _module.args.tmpfilesLib = {
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
  };
}
