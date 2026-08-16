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
      DynamicUser = true;
      NoNewPrivileges = true;
    };
  };
}
