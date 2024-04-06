{ config, lib, inputs, ... }:
let
  cfg = config.custom.nixpkgs-unstable;
in
{
  ###### interface
  options = with lib; {
    custom.nixpkgs-unstable = {
      enable = mkEnableOption "Nixpkgs Unstable" // { default = true; };

      settings = mkOption {
        type = types.unspecified;
        default = { inherit (config.nixpkgs) system config overlays; };
      };
    };
  };

  ###### implementation
  config = lib.mkIf cfg.enable {
    _module.args.pkgs-unstable = import inputs.nixpkgs-unstable cfg.settings;
  };
}
