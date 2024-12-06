{ lib, ... }: {
  options = {
    # See https://discourse.nixos.org/t/how-can-i-configure-default-values-lib-mkdefault-for-options-in-a-submodule-option/42100/3
    # See https://github.com/NixOS/nixpkgs/issues/24653#issuecomment-292684727
    virtualisation.quadlet.containers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        config = {
          containerConfig = {
            podmanArgs = lib.mkDefault [ "--stop-timeout=20" ];
          };

          serviceConfig = {
            Restart = "on-failure";
            TimeoutStopSec = 30;
            TimeoutStartSec = 900;
          };
        };
      });
    };
  };
}
