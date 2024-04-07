{ config, lib, pkgs, ... }:
let
  cfg = config.custom.activation.diff;
in
{

  ###### interface
  options = with lib; {
    custom.activation.diff = {
      enable = mkEnableOption "Show Diff between generations on activation";
    };
  };

  ###### implementation
  config = lib.mkIf cfg.enable {
    system.activationScripts.diff = {
      supportsDryActivation = true;
      text = ''
        if [[ -e /run/current-system ]]; then
          ${lib.getExe pkgs.nvd} --color=always --nix-bin-dir=${config.nix.package}/bin diff /run/current-system "$systemConfig"
        fi
      '';
    };
  };
}
