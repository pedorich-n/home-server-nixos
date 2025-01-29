{ inputs, flake, flake-parts-lib, lib, ... }: {
  imports = [ inputs.terranix.flakeModule ];

  options = {
    perSystem = flake-parts-lib.mkPerSystemOption {
      options.terranix = {
        terranixConfigurations = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              terraformWrapper = lib.mkOption {
                type = lib.types.submodule {
                  config = {
                    prefixText = lib.mkBefore ''
                      if [ "''${CI:-false}" = "false" ]; then
                        if ! [ -x "$(command -v op)" ]; then
                          echo "Error: 1Password CLI (op) not found in PATH!" >&2
                          exit 1
                        fi

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
          });

        };
      };
    };
  };

  config = {

    perSystem = {
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
            workdir = "./terranix/backblaze/workdir";

            modules = flake.lib.loaders.listFilesRecursively { src = ../terranix/backblaze; };
          };
        };
      };
    };
  };
}
