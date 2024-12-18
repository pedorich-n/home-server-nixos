{ lib, config, ... }:
let
  mkImage = name:
    let
      container = config.custom.containers.${name} or (builtins.throw "Can't find container info for '${name}'");
    in
    "${container.registry}/${container.container}:${container.version}";
in
{
  options = {
    # See https://discourse.nixos.org/t/how-can-i-configure-default-values-lib-mkdefault-for-options-in-a-submodule-option/42100/3
    # See https://github.com/NixOS/nixpkgs/issues/24653#issuecomment-292684727
    virtualisation.quadlet.containers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ name, config, ... }: {
        options = {
          requiresTraefikNetwork = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          wantsAuthentik = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          useGlobalContainers = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
        };

        config = lib.mkMerge [
          {
            containerConfig = {
              podmanArgs = lib.mkDefault [ "--stop-timeout=20" ];
            };

            serviceConfig = {
              Restart = lib.mkDefault "on-failure";
              TimeoutStopSec = lib.mkDefault 30;
              TimeoutStartSec = lib.mkDefault 900;
              SuccessExitStatus = [
                143 # container shut down gracefully after receiving a SIGTERM
              ];
            };
          }
          (lib.mkIf config.useGlobalContainers {
            containerConfig.image = mkImage name;
          })
          (lib.mkIf config.requiresTraefikNetwork {
            containerConfig.networks = lib.mkAfter [ "traefik.network" ];
          })
          (lib.mkIf config.wantsAuthentik {
            unitConfig = {
              Wants = lib.mkAfter [ "authentik-server.service" ];
              After = lib.mkAfter [ "authentik-server.service" ];
            };
          })
        ];
      }));
    };
  };
}
