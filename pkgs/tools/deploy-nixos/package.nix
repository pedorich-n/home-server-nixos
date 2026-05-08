{
  flake,
  writeShellApplication,
  deploy-rs,
}:
writeShellApplication {
  name = "deploy-nixos";
  meta.description = "Deploy given NixOS configuration to remote machines using deploy-rs";
  runtimeInputs = [
    deploy-rs
  ];
  text = ''
    nixos_config=$1
    shift 1

    deploy "${flake}#''${nixos_config}" "$@"
  '';
}
