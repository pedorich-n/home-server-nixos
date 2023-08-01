{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.custom.environment.mutable-files;

  mutableFileSubmodule = types.submodule {
    options = {
      source = mkOption {
        type = types.path;
        description = lib.mdDoc "Path of the source file.";
      };
      # TODO: permission bits?
    };
  };

  activationCommand =
    let
      activateSingleEntry = { source, destination }: ''
        ${pkgs.python3Minimal}/bin/python3 ${./manage-files.py} --source ${source} --destination ${destination} ''${MAYBE_DRY_RUN:-}
      '';
    in
    ''
      if [ "$NIXOS_ACTION" == "dry-activate" ]; then
        export MAYBE_DRY_RUN="--dry-run"
      fi
          
      ${concatLines (mapAttrsToList (destination: source: activateSingleEntry { inherit (source) source; inherit destination; }) cfg)}
    '';
in
{
  ###### interface
  options = {
    custom.environment.mutable-files = mkOption {
      type = types.attrsOf mutableFileSubmodule;
    };
  };

  ###### implementation
  config = {
    system.activationScripts.mutable-files = {
      supportsDryActivation = true;
      deps = [ "users" "groups" "specialfs" ];
      text = traceVal activationCommand;
    };
  };
}
