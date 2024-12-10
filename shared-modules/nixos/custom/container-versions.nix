{ flake, lib, ... }:
let
  versionsRaw = lib.importJSON "${flake}/containers/versions.json";
  versions = builtins.mapAttrs (_: value: value.version) versionsRaw.data;
in
{

  ###### interface
  options = with lib; {
    custom.containers.versions = mkOption {
      type = with types; attrsOf str;
      description = "Attrs where key is the name of the container, and value is the version";
      readOnly = true;
    };
  };

  ###### implementation
  config = {
    custom.containers.versions = versions;
  };
}
