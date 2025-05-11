{ config, lib, pkgs-unstable, ... }: {
  programs.superfile = {
    enable = true;
    package = pkgs-unstable.superfile;
  };

  home.shellAliases = lib.mkIf config.programs.superfile.enable {
    spf = "superfile";
  };
}
