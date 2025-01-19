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
                    extraRuntimeInputs = [ pkgs.gitMinimal pkgs.jq ];
                    prefixText = lib.mkBefore ''
                      if [ "''${CI:-false}" = "false" ]; then
                        ROOT="$(git rev-parse --show-toplevel)"
                        WORKDIR="${lib.escapeShellArg config.workdir}"
                        # shellcheck disable=SC1090,SC1091
                        source "$ROOT/$(dirname $WORKDIR)/.env"

                        OP_ACCOUNT=$(op account list --format=json | jq -r '.[0] | .user_uuid')
                        export OP_ACCOUNT
                      fi
                    '';
                  };
                };
              };
            };
            config = {
              modules = lib.mkBefore ([
                {
                  _module.args = {
                    inherit flake;
                    hostname = flake.nixosConfigurations.geekomA5.config.networking.hostName;
                    domain = flake.nixosConfigurations.geekomA5.config.custom.networking.domain;
                  };
                }
              ] ++ (flake.lib.loaders.listFilesRecursively { src = "${flake}/shared-modules/terranix"; }));
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
              workdir = "./terranix/tailscale/workdir";

              modules = flake.lib.loaders.listFilesRecursively { src = ../terranix/tailscale; };
            };

            arr-stack = {
              workdir = "./terranix/arr-stack/workdir";

              modules = [
                {
                  _module.args = {
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
                  if [ "''${CI:-false}" = "false" ]; then
                    op_path="op://HomeLab/Backblaze_Terranix"
                    B2_APPLICATION_KEY=$(op read "''${op_path}/application_key")
                    B2_APPLICATION_KEY_ID=$(op read "''${op_path}/application_key_id")
                    export B2_APPLICATION_KEY B2_APPLICATION_KEY_ID
                  fi
                '';
              };

              workdir = "./terranix/backblaze/workdir";

              modules = flake.lib.loaders.listFilesRecursively { src = ../terranix/backblaze; };
            };
          };
        };
      };
  };
}
