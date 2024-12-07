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
              Restart = "on-failure";
              TimeoutStopSec = 30;
              TimeoutStartSec = 900;
            };
          }
          (lib.mkIf config.requiresTraefikNetwork {
            containerConfig.networks = [ "traefik" ];
            unitConfig = {
              Requires = [ "traefik-network.service" ];
              After = [ "traefik-network.service" ];
            };
          })
          (lib.mkIf config.wantsAuthentik {
            unitConfig = {
              Wants = [ "authentik-server.service" ];
              After = [ "authentik-server.service" ];
            };
          })
        ];
      }));
    };
  };
}
