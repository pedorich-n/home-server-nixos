{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.custom.playit;

  generateToml = filename: content: (pkgs.formats.toml { }).generate filename content;
  secret = generateToml "playit.toml" {
    secret_key = "be938ed30f0d5d36cbe01cd76125d8b307158fbd3993b278f1b505298b899afb";
  };
in
{
  ###### interface
  options = {
    custom.playit = {
      enable = mkEnableOption "Playit";
    };
  };

  ###### implementation
  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.playit-cli ];
    services.playit = {
      enable = true;
      secretPath = secret;
    };
  };
}
