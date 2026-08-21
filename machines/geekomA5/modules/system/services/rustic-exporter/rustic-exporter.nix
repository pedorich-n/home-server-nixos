{
  config,
  pkgs,
  lib,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.rustic-exporter;

  args = [
    "--host"
    "127.0.0.1"
    "--port"
    portsCfg.portStr
    "--config"
    "\${CONFIG_FILE}"
  ];
in
{
  custom = {
    networking.ports.tcp.rustic-exporter = {
      port = 33100;
      openFirewall = false;
    };

    services.caddy.metrics.routes = {
      rustic-exporter = {
        url = "http://127.0.0.1:${portsCfg.portStr}";
      };
    };
  };

  systemd.services.rustic-exporter = {
    enable = true;
    description = "Restic metrics exporter for Prometheus";
    after = [ "network.target" ];
    wants = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      CONFIG_FILE = "%d/config.toml";
    };

    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.rustic-exporter} ${lib.concatStringsSep " " args}";
      LoadCredential = [
        "config.toml:${config.sops.templates."rustic-exporter/config.toml".path}"
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
}
