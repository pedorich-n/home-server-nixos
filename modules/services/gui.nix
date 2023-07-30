{ config, lib, ... }:
with lib;
let
  cfg = config.custom.gui;
in
{
  ###### interface
  options = {
    custom.gui = {
      enable = mkEnableOption "GUI";
    };
  };

  ###### implementation
  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;
      displayManager.lightdm.enable = true;
      desktopManager.xfce.enable = true;
      layout = "us";
      xkbOptions = "grp:win_space_toggle";
    };
  };

}
