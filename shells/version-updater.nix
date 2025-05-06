{ pkgs, ... }:
pkgs.mkShellNoCC {
  name = "version-updater";

  packages = with pkgs; [
    nvchecker
    nvfetcher
  ];
}
