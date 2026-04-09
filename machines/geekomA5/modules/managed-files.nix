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

  mcpServerSubmodule = lib.types.submodule {
    options = {
      datasource = lib.mkOption {
        type = lib.types.nonEmptyStr;
      };

      package = lib.mkOption {
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
    custom.managed-files = {
      containers = mkOption {
        type = with types; attrsOf containerSubmodule;
        readOnly = true;
      };

      mcp-servers = mkOption {
        type = with types; attrsOf mcpServerSubmodule;
        readOnly = true;
      };
    };
  };

  config = {
    custom.managed-files = {
      containers = lib.mapAttrs (_: attrs: {
        inherit (attrs)
          registry
          image
          version
          digest
          ;
      }) (lib.importTOML "${flake}/managed-files/containers.toml");

      mcp-servers = lib.mapAttrs (_: attrs: {
        inherit (attrs)
          datasource
          package
          version
          ;
      }) (lib.importJSON "${flake}/managed-files/mcp-servers.json");
    };

  };
}
