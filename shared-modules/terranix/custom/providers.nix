{ flake, lib, ... }:
let
  providerSubmodule = lib.types.submodule {
    options = {
      source = lib.mkOption {
        type = lib.types.nonEmptyStr;
      };

      version = lib.mkOption {
        type = lib.types.nonEmptyStr;
      };
    };
  };
in
{
  options = {
    custom.providers = lib.mkOption {
      type = lib.types.attrsOf providerSubmodule;
      readOnly = true;
    };
  };

  config = {
    custom.providers = lib.importJSON "${flake}/versions/terraform-providers.json";
  };
}
