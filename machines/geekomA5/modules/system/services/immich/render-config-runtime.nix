{ config, lib, pkgs, authentikLib, ... }:
let
  cfg = config.custom.services.immich;

  variables = pkgs.writers.writeJSON "variables.json" {
    issuer = authentikLib.mkIssuerUrl "immich";
    domain = config.custom.networking.domain;
  };
in
{
  ###### interface
  options = with lib; {
    custom.services.immich = {
      configPath = mkOption {
        type = types.path;
        readOnly = true;
      };
    };
  };

  ###### implementation
  config = {
    custom.services.immich.configPath = "/run/immich-config/config.json";

    systemd.services."immich-render-config" = {
      wants = [ "run-agenix.d.mount" ];
      after = [ "run-agenix.d.mount" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RuntimeDirectory = "immich-config";
        RuntimeDirectoryPreserve = true;

        ExecStart = lib.getExe (pkgs.writeShellApplication {
          name = "immich-render-config";
          runtimeInputs = [ pkgs.jinja2-renderer ];
          text = ''
            jinja2-renderer --variables "${variables}" \
              --variables "${config.age.secrets.immich_secrets.path}" \
              --templates "${./templates}" \
              --output "${lib.removeSuffix (builtins.baseNameOf cfg.configPath) cfg.configPath}"
          '';
        });
      };
    };
  };

}
