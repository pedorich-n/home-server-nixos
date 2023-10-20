{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.playit;
in
{
  ###### interface
  options = {
    services.playit = {
      enable = mkEnableOption "Playit Service";

      package = mkOption {
        type = types.package;
        default = pkgs.playit-cli;
        description = "Playit binary to run";
      };

      secretPath = mkOption {
        type = types.path;
        description = "Path to TOML file containing secret";
      };
    };
  };

  ###### implementation
  config = mkIf cfg.enable {
    systemd.services.playit = {
      description = "Playit Agent";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      script = ''
        ${getExe cfg.package} --secret_path ${cfg.secretPath}
      '';
    };
  };
}
