{
  config,
  lib,
  pkgs,
  ...
}:
{
  security.sudo = {
    extraRules = [
      {
        groups = [
          config.users.groups.tomb.name
        ];
        commands = [
          {
            command = lib.getExe pkgs.custom-tomb.open;
            options = [ "NOPASSWD" ];
          }
          {
            command = lib.getExe pkgs.custom-tomb.close;
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    extraConfig = ''
      Defaults:%${config.users.groups.tomb.name} env_keep += "TOMB_KEY_PASS"
    '';
  };
}
