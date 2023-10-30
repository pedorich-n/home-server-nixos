{ config, lib, pkgs-unstable, ... }:
with lib;
let
  cfg = config.custom.services.server-check;
in
{
  ###### interface
  options = {
    custom.services.server-check = {
      enable = mkEnableOption "GUI";
    };
  };

  ###### implementation
  config = mkIf cfg.enable {
    systemd.services.minecraft-server-check = {
      description = "Minecraft Server and Tunnel health-check";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "systemd-resolved.service" ];
      startAt = "*-*-* *:*:00"; # Every minute

      script = ''
        ${getExe pkgs-unstable.server-check} --config ${config.age.secrets.server-check-config.path}
      '';

      serviceConfig = {
        Restart = "on-failure";
      };
    };
  };

}
