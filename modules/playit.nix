{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.custom.playit;
in
{
  ###### interface
  options = {
    custom.playit = {
      enable = mkEnableOption "Playit";
    };
  };

  ###### implementation
  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.playit-cli ];
    services.playit = {
      enable = true;
      user = config.users.users.user.name;
      group = config.users.users.user.group;
      secretPath = config.age.secrets.playit-secret.path;
      runOverride = {
        "62884177-5592-45a9-9662-492b42407881".port = 43000;
        "5ee160f1-2374-454a-8c00-81bf4747855f".port = 19132;
      };
    };
  };
}
