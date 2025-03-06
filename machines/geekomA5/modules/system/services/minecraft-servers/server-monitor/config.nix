{ config, pkgs, lib, ... }:
let
  cfg = config.custom.minecraft-servers.check;

  mkSystemdEntries = serverName: serverCfg:
    let
      unitName = "minecraft-servers-health-check-${serverName}";
      serverUnitName = "minecraft-server-${serverName}.service";
    in
    {
      services.${unitName} = {
        description = "HealthCheck for Minecraft server ${serverName}";
        wantedBy = [ "multi-user.target" ];
        bindsTo = [ serverUnitName ];
        after = [
          "network.target"
          # serverUnitName
        ];

        serviceConfig = {
          User = config.services.minecraft-servers.user;
          Group = config.services.minecraft-servers.group;
          ExecStart = lib.getExe (pkgs.callPackage ./_monitor.nix {
            systemd = config.systemd.package;
            inherit serverName;
            serverAddress = serverCfg.address;
            serverPort = serverCfg.port;
            # notifySocket = serverCfg.notify.socket;
            pidPath = serverCfg.notify.pidPath;

            interval = "${builtins.toString serverCfg.healthCheck.intervalSeconds}s";
            inherit (serverCfg.healthCheck) retries;
          });
        };
      };

      timers.${unitName} = {
        description = "HealthCheck trigger for Minecraft server ${serverName}";
        wantedBy = [ "multi-user.target" ];
        bindsTo = [ serverUnitName ];

        timerConfig = {
          OnUnitActiveSec = "${builtins.toString serverCfg.notify.intervalSeconds}s";
          Unit = "${unitName}.service";
        };
      };
    };
in
{
  config = lib.mkIf cfg.enable {
    systemd = lib.mkMerge (lib.mapAttrsToList mkSystemdEntries cfg.servers);
  };
}
