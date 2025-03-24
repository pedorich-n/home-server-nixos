{ config, lib, pkgs, ... }:
let
  cfg = config.custom.services.prometheus-podman-exporter;
in
{
  options = {
    custom.services.prometheus-podman-exporter = {
      enable = lib.mkEnableOption "prometheus-podman-exporter";

      package = lib.mkPackageOption pkgs "prometheus-podman-exporter" { };

      listenAddress = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "0.0.0.0";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 9882;
      };

      extraFlags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };
  };

  config.virtualisation.containers.containersConf.settings = {
    engine = {
      helper_binaries_dir = [
        "${config.virtualisation.podman.package}/libexec/podman"
      ];
    };
  };

  config.systemd.services = lib.mkIf (config.virtualisation.podman.enable && cfg.enable) {
    prometheus-podman-exporter = {
      description = "Prometheus Podman exporter";
      wantedBy = [ "default.target" ];
      after = [
        "podman.socket"
        "network.target"
      ];

      path = with pkgs; [
        runc
        crun
        conmon
      ];

      # environment = {
      #   PATH = "${config.virtualisation.podman.package}/libexec/podman";
      # };
      serviceConfig = {
        Restart = "on-failure";
        ExecStart = ''
          ${lib.getExe cfg.package} \
            --web.listen-address="${cfg.listenAddress}:${builtins.toString cfg.port}" \
            ${lib.concatStringsSep " \\\n  " cfg.extraFlags}
        '';
      };
    };
  };
}
