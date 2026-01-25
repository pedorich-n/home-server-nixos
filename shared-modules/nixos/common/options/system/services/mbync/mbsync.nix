{
  config,
  lib,
  utils,
  pkgs,
  ...
}:
let
  # Utils from https://github.com/NixOS/nixpkgs/blob/4930931c997bcf/nixos/modules/misc/extra-arguments.nix#L9-L11
  inherit (utils.systemdUtils.unitOptions) unitOption;

  cfg = config.custom.services.mbsync;

  args = [
    "--all"
    "--config"
    "%d/config"
  ]
  ++ (lib.optional cfg.verbose "--verbose")
  ++ (lib.optional cfg.dryRun "--dry-run");
in
{
  options.custom.services.mbsync = {
    enable = lib.mkEnableOption "Enable mbsync mail synchronization service.";

    package = lib.mkPackageOption pkgs "isync" { };

    configFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the mbsync configuration file.";
    };

    localMailboxes = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      description = "List of local mailbox root directories. Used to assign proper permissions to mail directories.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "mail";
      description = "Group under which mbsync will run and own mail directories.";
    };

    verbose = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable verbose output for mbsync.";
    };

    dryRun = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "If true, mbsync will perform a trial run with no changes made.";
    };

    timerConfig = lib.mkOption {
      type = lib.types.nullOr (lib.types.attrsOf unitOption);
      default = null;
      description = ''
        When to run the backup. See {manpage}`systemd.timer(5)` for
        details. If null no timer is created and sync will only
        run when explicitly started.
      '';
      example = {
        OnCalendar = "00:05";
        RandomizedDelaySec = "5h";
        Persistent = true;
      };
    };

  };

  config = lib.mkIf cfg.enable {
    users.groups."${cfg.group}" = { };

    systemd = {
      timers.mbsync = lib.mkIf (cfg.timerConfig != null) {
        description = "Timer for mbsync";
        wantedBy = [ "timers.target" ];

        timerConfig = cfg.timerConfig;
      };

      services.mbsync = {
        description = "Mail synchronization using mbsync";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        environment = {
          "HOME" = "/run/mbsync";
        };

        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''
            ${lib.getExe' cfg.package "mbsync"} ${lib.concatStringsSep " " args}
          '';
          RuntimeDirectory = "mbsync";
          Group = cfg.group;

          LoadCredential = [
            "config:${cfg.configFile}"
          ];

          # Hardening
          ReadWritePaths = cfg.localMailboxes;
          NoNewPrivileges = true;
          MemoryDenyWriteExecute = true;
          LockPersonality = true;
          PrivateDevices = true;
          PrivateTmp = true;
          PrivateUsers = true;
          PrivateMounts = true;
          DynamicUser = true;
          ProtectHome = true;
          ProtectSystem = "strict";
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          ProtectClock = true;
          RestrictSUIDSGID = true;
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
          ];
        };
      };
    };
  };
}
