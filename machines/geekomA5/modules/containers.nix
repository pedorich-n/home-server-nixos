{ flake, lib, ... }:
let
  containerSubmodule = lib.types.submodule {
    options = {
      registry = lib.mkOption {
        type = lib.types.nonEmptyStr;
      };

      image = lib.mkOption {
        type = lib.types.nonEmptyStr;
      };

      version = lib.mkOption {
        type = lib.types.nonEmptyStr;
      };

      digest = lib.mkOption {
        type = lib.types.nonEmptyStr;
      };
    };
  };

  rawToml = lib.importTOML "${flake}/managed-files/containers.toml";
  containers = lib.mapAttrs (_: attrs: {
    inherit (attrs)
      registry
      image
      version
      digest
      ;
  }) rawToml;
in
{
  options = with lib; {
    custom.containers = mkOption {
      type = with types; attrsOf containerSubmodule;
      readOnly = true;
    };
  };

  config = {
    custom.containers = containers;
  };
}
