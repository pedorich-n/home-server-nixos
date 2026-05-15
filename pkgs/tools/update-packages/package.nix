{
  packages,
  writeShellApplication,
  nix-update,
  lib,
}:
let
  eligiblePackages = lib.filterAttrs (_name: pkg: pkg ? passthru.useNixUpdate && pkg.passthru.useNixUpdate) packages;
  mkUpdateCommand = arg: ''
    echo "Updating ${arg}..."
    nix-update --flake \"${arg}\" || failed=1
    echo ""
  '';
  lines = lib.concatMapStringsSep "\n" mkUpdateCommand (lib.attrNames eligiblePackages);
in
writeShellApplication {
  name = "update-packages";
  meta.description = "Update packages' sources using nix-update";

  runtimeInputs = [
    nix-update
  ];

  text = ''
    failed=0

    ${lines}

    exit "$failed"
  '';
}
