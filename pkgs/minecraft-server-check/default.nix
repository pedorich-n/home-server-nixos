{ pkgs, ... }:
pkgs.poetry2nix.mkPoetryApplication {
  projectDir = ./.;
  overrides = pkgs.poetry2nix.overrides.withDefaults (_: prev: {
    pystemd = prev.pystemd.overridePythonAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.pkg-config ];
      buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.systemd ];
    });
    mcstatus = prev.mcstatus.override {
      preferWheel = true;
    };
  });
}
