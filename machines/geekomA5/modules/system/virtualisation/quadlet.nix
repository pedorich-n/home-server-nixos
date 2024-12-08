{ lib, ... }:
{
  options = {
    # See https://discourse.nixos.org/t/how-can-i-configure-default-values-lib-mkdefault-for-options-in-a-submodule-option/42100/3
    # See https://github.com/NixOS/nixpkgs/issues/24653#issuecomment-292684727
    virtualisation.quadlet.containers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ config, ... }: {
        options = {
          requiresTraefikNetwork = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          wantsAuthentik = lib.mkOption {
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
          (lib.mkIf config.requiresTraefikNetwork {
            containerConfig.networks = lib.mkAfter [ "traefik" ];
            unitConfig = {
              Requires = lib.mkAfter [ "traefik-network.service" ];
              After = lib.mkAfter [ "traefik-network.service" ];
            };
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
