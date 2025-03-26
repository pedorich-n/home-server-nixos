{ flake, lib, ... }:
let
  containerSubmodule = lib.types.submodule {
    options = {
      registry = lib.mkOption {
        type = lib.types.nonEmptyStr;
      };

      container = lib.mkOption {
        type = lib.types.nonEmptyStr;
      };

      version = lib.mkOption {
        type = lib.types.nonEmptyStr;
      };
    };
  };
in
{
  options = with lib; {
    custom.containers = mkOption {
      type = with types; attrsOf containerSubmodule;
      readOnly = true;
    };
  };

  config = {
    custom.containers = lib.importJSON "${flake}/versions/containers.json";
  };
}
