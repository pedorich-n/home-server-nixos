# Based on https://github.com/hercules-ci/flake-parts/issues/220#issuecomment-2053718001
{ lib, flake-parts-lib, ... }: {
  options = {
    flake = flake-parts-lib.mkSubmoduleOptions {
      lib = lib.mkOption {
        type = lib.types.raw;
        default = { };
        description = ''
          Global lib functions
        '';
      };
    };
  };
}
