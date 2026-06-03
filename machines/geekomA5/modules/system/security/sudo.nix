{
  config,
  lib,
  pkgs,
  ...
}:
{
  security.sudo.extraRules = [
    {
      groups = [
        config.users.groups.tomb.name
      ];
      commands = [
        {
          command = lib.getExe pkgs.custom-tomb.open;
          options = [
            "NOPASSWD"
            "SETENV"
          ];
        }
        {
          command = lib.getExe pkgs.custom-tomb.close;
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
