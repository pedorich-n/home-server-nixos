{
  config,
  pkgs,
  lib,
  systemdLib,
  ...
}:
let
  cfg = config.custom.services.safebucket;
in
{

  options = {
    custom.services.safebucket = {
      enable = lib.mkEnableOption "Enable safebucket service.";

      package = lib.mkPackageOption pkgs "safebucket" { };

      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/safebucket";
        description = ''
          Path to store safebucket data.
          This path will be used for the following default environment variables:
          - DATABASE__SQLITE__PATH
          - ACTIVITY__FILESYSTEM__DIRECTORY
          - NOTIFIER__FILESYSTEM__DIRECTORY
        '';
      };

      environment = lib.mkOption {
        type = with lib.types; attrsOf str;
        default = {
          APP__LOG_LEVEL = "info";
          APP__PORT = 8080;

          DATABASE__TYPE = "sqlite";
          DATABASE__SQLITE__PATH = "${cfg.dataDir}/safebucket.db";

          CACHE__TYPE = "memory";

          ACTIVITY__TYPE = "filesystem";
          ACTIVITY__FILESYSTEM__DIRECTORY = "${cfg.dataDir}/activity";

          NOTIFIER__TYPE = "filesystem";
          NOTIFIER__FILESYSTEM__DIRECTORY = "${cfg.dataDir}/notifications";
        };
        description = ''
          Environment variables to set for the safebucket service.
          See <https://docs.safebucket.io/configuration/environment-variables> for more information.
        '';
      };

      environmentFiles = lib.mkOption {
        type = with lib.types; listOf path;
        default = [ ];
        example = [ "/run/secrets/safebucket.env" ];
        description = ''
          Files to load environment variables from in addition to [](#opt-services.safebucket.environment).
          This is useful to avoid putting secrets into the nix store.
          See <https://docs.safebucket.io/configuration/environment-variables> for more information.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.safebucket = {
      description = "Safebucket service";
      after = [ "network.target" ];
      wants = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = cfg.environment;

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        StateDirectory = "safebucket";
        StateDirectoryMode = "0750";
        EnvironmentFile = cfg.environmentFiles;

        ReadWritePaths = cfg.dataDir;

        # Hardening
        DynamicUser = true;
        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        LockPersonality = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = true;
        PrivateUsers = true;
        ProtectSystem = "strict";
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        ProtectHostname = true;
        ProtectProc = "invisible";
        MemoryDenyWriteExecute = true;
        RestrictNamespaces = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "@chown"
        ];

        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
      };

      unitConfig = lib.mkMerge [
        {
          RequiresMountsFor = [ cfg.dataDir ];
        }
        (systemdLib.wantsAfter [
          config.systemd.services.caddy.name
        ])
        (systemdLib.requisiteAfter [
          config.systemd.services.authelia-main.name
        ])
      ];
    };
  };
}
