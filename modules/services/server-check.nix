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

      server = mkOption {
        type = types.str;
      };
    };
  };

  ###### implementation
  config = mkIf cfg.enable {
    systemd.services.minecraft-server-check = {
      description = "Minecraft Server and Tunnel health-check";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "systemd-resolved.service" cfg.server ];
      partOf = [ cfg.server ];
      requires = [ cfg.server ];

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
