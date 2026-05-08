{
  flake,
  writeShellApplication,
}:
writeShellApplication {
  name = "build-iso";
  meta.description = "Build NixOS ISO image from a given configuration";
  text = ''
    nixos_config=$1
    shift 1

    nix build "${flake}#nixosConfigurations.''${nixos_config}.config.system.build.isoImage" "$@"
  '';
}
