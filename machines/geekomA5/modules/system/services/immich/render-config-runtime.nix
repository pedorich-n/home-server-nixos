{ config, lib, pkgs, authentikLib, ... }:
let
  cfg = config.custom.services.immich;
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

      environment = {
        HOME = cfg.configPath;
      };

      serviceConfig = {
        Type = "oneshot";
        RuntimeDirectory = "immich-config";
        RuntimeDirectoryPreserve = true;

        ExecStart = lib.getExe (pkgs.writeShellApplication {
          name = "immich-render-config";
          runtimeInputs = [ pkgs.jinja2-cli ];
          text = ''
            jinja2 -D issuer="${authentikLib.mkIssuerUrl "immich"}" \
              --format=json \
              "${./config.json}" \
              "${config.age.secrets.immich_secrets.path}" \
              --outfile "${cfg.configPath}"
          '';
        });
      };
    };
  };

}
