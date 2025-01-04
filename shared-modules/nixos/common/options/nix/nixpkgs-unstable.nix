{ inputs, config, lib, pkgs, ... }:
let
  cfg = config.custom.nixpkgs-unstable;
in
{
  ###### interface
  options = with lib; {
    custom.nixpkgs-unstable = {
      enable = mkEnableOption "Nixpkgs Unstable";

      settings = mkOption {
        type = types.unspecified;
        default = {
          inherit (pkgs) config overlays;
          inherit (pkgs.stdenv.hostPlatform) system;
        };
      };
    };
  };

  ###### implementation
  config = lib.mkIf cfg.enable {
    _module.args.pkgs-unstable = import inputs.nixpkgs-unstable cfg.settings;
  };
}
