{ inputs, flake, flake-parts-lib, lib, ... }: {
  imports = [ inputs.terranix.flakeModule ];

  options = {
    perSystem = flake-parts-lib.mkPerSystemOption ({ pkgs, ... }: {
      options.terranix = {
        terranixConfigurations = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule ({ config, ... }: {
            options = {
              terraformWrapper = lib.mkOption {
                type = lib.types.submodule {
                  config = {
                    extraRuntimeInputs = [ pkgs.gitMinimal ];
                    prefixText = lib.mkBefore ''
                      ROOT="$(git rev-parse --show-toplevel)"
                      # shellcheck disable=SC1090,SC1091
                      source "$ROOT/$(dirname ${config.workdir})/.env"
                    '';
                  };
                };
              };
            };
          }));

        };
      };
    });
  };

  config = {

    perSystem = { pkgs, ... }:
      {
        terranix = {
          setDevShell = true;

          terranixConfigurations = {
            tailscale = {
              workdir = "./terranix/tailscale/state";

              modules = [
                { _module.args.flake = flake; }
              ] ++ flake.lib.loaders.listFilesRecursively { src = ../terranix/tailscale; };
            };

            arr-stack = {
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

            backblaze = {
              terraformWrapper = {
                extraRuntimeInputs = [
                  pkgs._1password-cli
                ];

                prefixText = ''
                  op_path="op://Server/Backblaze_Terranix"
                  B2_APPLICATION_KEY=$(op read "''${op_path}/application_key")
                  B2_APPLICATION_KEY_ID=$(op read "''${op_path}/application_key_id")
                  export B2_APPLICATION_KEY B2_APPLICATION_KEY_ID
                '';
              };

              workdir = "./terranix/backblaze/state";

              modules = flake.lib.loaders.listFilesRecursively { src = ../terranix/backblaze; };
            };
          };
        };
      };
  };
}
