{
  flake,
  writeShellApplication,
}:
writeShellApplication {
  name = "build-iso";
  meta.description = "Build NixOS ISO image from a given configuration";
  text = ''
    system=$1
    shift 1

    nix build "${flake}#nixosConfigurations.''${system}.config.system.build.isoImage" "$@"
  '';
}
