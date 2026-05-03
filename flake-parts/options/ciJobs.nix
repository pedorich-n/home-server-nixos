{
  flake-parts-lib,
  lib,
  ...
}:
flake-parts-lib.mkTransposedPerSystemModule {
  name = "ciJobs";
  option = lib.mkOption {
    type = with lib.types; lazyAttrsOf package;
    default = { };
    description = ''
      Derivations to be built by CI jobs.
    '';
  };
  file = ./ciJobs.nix;
}
