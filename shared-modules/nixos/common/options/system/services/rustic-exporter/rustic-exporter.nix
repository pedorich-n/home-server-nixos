{
  config,
  pkgs,
  lib,
  ...
}:
let

  cfg = config.custom.services.rustic-exporter;

  args = [
    "--host"
    cfg.host
    "--port"
    (toString cfg.port)
    "--output"
    cfg.outputType
    "--log-level"
    cfg.logLevel
    "--interval"
    (toString cfg.interval)
    "--config"
    "\${CONFIG_FILE}"
  ];
in
{

  options = {
    custom.services.rustic-exporter = {
      enable = lib.mkEnableOption "rustic-exporter";

      package = lib.mkPackageOption pkgs "rustic-exporter" { };

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        example = "0.0.0.0";
        description = "Adress on which rustic-exporter listens";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
        example = 9000;
        description = "Port on which rustic-exporter listens";
      };

      configFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to a TOML config file
          See <https://github.com/timtorChen/rustic-exporter#configuration-file> for more information.
        '';
      };

      interval = lib.mkOption {
        type = lib.types.ints.positive;
        default = 300;
        example = 1500;
        description = "Metrics collection frequency in seconds";
      };

      logLevel = lib.mkOption {
        type = lib.types.enum [
          "debug"
          "info"
          "warn"
          "error"
        ];
        default = "info";
        example = "warn";
        description = "Log level for rustic-exporter";
      };

      outputType = lib.mkOption {
        type = lib.types.enum [
          "text"
          "json"
        ];
        default = "text";
        example = "json";
        description = "Output format of the logs";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.rustic-exporter = {
      enable = true;
      description = "Rustic metrics exporter for Prometheus";
      after = [ "network.target" ];
      wants = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        CONFIG_FILE = "%d/config.toml";
      };

      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.rustic-exporter} ${lib.concatStringsSep " " args}";
        LoadCredential = [
          "config.toml:${cfg.configFile}"
        ];
        Restart = "on-failure";
        RestartSec = 5;

        # Hardening
        CapabilityBoundingSet = "";
        DynamicUser = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
        UMask = "0077"; # 600 for files, 700 for dirs
      };
    };
  };
}
