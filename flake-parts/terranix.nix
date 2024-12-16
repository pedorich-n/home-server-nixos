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
              {
                _module.args = {
                  inherit flake;
                  inherit (inputs) trash-guides;
                };
              }
            ] ++ flake.lib.loaders.listFilesRecursively { src = ../terranix/arr-stack; };
          };

          backblaze = rec {
            terraformWrapper = {
              extraRuntimeInputs = [
                pkgs._1password-cli
                pkgs.gitMinimal
              ];

              prefixText = ''
                ROOT="$(git rev-parse --show-toplevel)"
                # shellcheck disable=SC1090,SC1091
                source "$ROOT/$(dirname ${workdir})/.env"

                op_path="op://Server/Backblaze_Terranix"
                B2_APPLICATION_KEY=$(op read "''${op_path}/application_key")
                B2_APPLICATION_KEY_ID=$(op read "''${op_path}/application_key_id")
                export B2_APPLICATION_KEY B2_APPLICATION_KEY_ID
              '';
            };

            workdir = "./terranix/backblaze/state";

            modules = [
              {
                # _module.args = {
                #   inherit flake;
                #   inherit (inputs) trash-guides;
                # };
              }
            ] ++ flake.lib.loaders.listFilesRecursively { src = ../terranix/backblaze; };
          };
        };
      };
    };
}
