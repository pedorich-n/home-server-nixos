{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    package = pkgs.yazi.override { extraPackages = [ pkgs.exiftool ]; };
    settings = {
      manager = {
        show_hidden = true;
        show_symlink = true;
      };
    };
  };
}
