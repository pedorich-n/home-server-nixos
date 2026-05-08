{
  flake,
  lib,
  writeShellApplication,
  deploy-rs,
}:
writeShellApplication {
  name = "deploy-nixos";
  meta.description = "Deploy given NixOS configuration to remote machines using deploy-rs";
  program = ''
    system=$1
    shift 1

    ${lib.getExe deploy-rs} "${flake}#$system" "$@"
  '';
}
