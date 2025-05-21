{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "update-cockpit-plugins";

  runtimeInputs = [
    pkgs.nvfetcher
    pkgs.gitMinimal
  ];

  text = ''
    ROOT="$(git rev-parse --show-toplevel)"
    TARGET="''${ROOT}/pkgs/cockpit-plugins/_sources"

    nvfetcher --config ${./nvfetcher.toml} --build-dir "$TARGET"
  '';
}
