{ lib, ... }: {
  programs.nh.clean.enable = lib.mkOverride 950 false;
}
