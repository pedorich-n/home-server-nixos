{ config, lib, utils, ... }:
let
  cfg = config.custom.services.minecraft-server-check;
in
{
  ###### interface
  options = with lib; {
    custom.services.minecraft-server-check = {
      enable = mkEnableOption "Minecraft Server Check";

      package = mkOption {
        type = types.package;
      };

      configPath = mkOption {
        type = types.path;
      };

      server-service = mkOption {
        type = utils.systemdUtils.lib.unitNameType;
        description = "Name of the systemd Minecraft server service";
      };

      tunnel-service = mkOption {
        type = utils.systemdUtils.lib.unitNameType;
        description = "Name of the systemd tunnel service";
      };

      interval = mkOption {
        type = types.int;
        default = 60;
        description = "How often to check server health (in seconds)";
      };

      timeout = mkOption {
        type = types.int;
        default = 10;
        description = "Timeout in seconds to wait for server's response";
      };

      restart-timeout = mkOption {
        type = types.int;
        default = 120;
        description = "Timeout in seconds to wait after server restart, before attempting another check";
      };

    };
  };

  ###### implementation
  config = lib.mkIf cfg.enable {
    systemd.services.minecraft-server-check = {
      description = "Minecraft Server and Tunnel health-check";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        cfg.server-service
        cfg.tunnel-service
      ];
      requires = [ cfg.server-service ];

      script = builtins.concatStringsSep " " [
        "${lib.getExe cfg.package}"
        "--config ${cfg.configPath}"
        "--server-service ${cfg.server-service}"
        "--tunnel-service ${cfg.tunnel-service}"
        "--interval ${toString cfg.interval}"
        "--timeout ${toString cfg.timeout}"
        "--restart-timeout ${toString cfg.restart-timeout}"
      ];

      serviceConfig = {
        Restart = "on-failure";
      };
    };
  };

}
