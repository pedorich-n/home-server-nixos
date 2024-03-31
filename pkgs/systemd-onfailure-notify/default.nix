{ poetry2nix, systemd }:
poetry2nix.mkPoetryApplication {
  projectDir = ./.;
  meta.mainProgram = "systemd-onfailure-notify";

  checkGroups = [ ];
  propagatedBuildInputs = [ systemd ];

  overrides = poetry2nix.overrides.withDefaults (_: prev: {
    apprise = prev.apprise.overridePythonAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.babel ];
    });
  });
}
