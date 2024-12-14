{ inputs, flake, ... }: {
  imports = [ inputs.terranix.flakeModule ];

  perSystem = { pkgs, ... }:
    let
      mkWrapper = workdir: {
        extraRuntimeInputs = [ pkgs.gitMinimal ];
        prefixText = ''
          ROOT="$(git rev-parse --show-toplevel)"
          # shellcheck disable=SC1090,SC1091
          source "$ROOT/$(dirname ${workdir})/.env"
        '';
      };
    in
    {
      terranix = {
        setDevShell = true;

        terranixConfigurations = {
          tailscale = rec {
            terraformWrapper = mkWrapper workdir;

            workdir = "./terranix/tailscale/state";

            modules = [
              { _module.args.flake = flake; }
            ] ++ flake.lib.loaders.listFilesRecursively { src = ../terranix/tailscale; };
          };

          arr-stack = rec {
            terraformWrapper = mkWrapper workdir;

            workdir = "./terranix/arr-stack/state";

            modules = [
              { _module.args.flake = flake; }
            ] ++ flake.lib.loaders.listFilesRecursively { src = ../terranix/arr-stack; };
          };
        };
      };
    };
}
