{ poetry2nix, systemd, pkgs, ... }:
poetry2nix.mkPoetryApplication {
  projectDir = ./.;
  meta.mainProgram = "systemd-onfailure-notify";

  checkGroups = [ ];
  propagatedBuildInputs = [ systemd ];

  overrides = poetry2nix.overrides.withDefaults (_: _prev: {
    apprise = pkgs.python3Packages.apprise;
  });
}
