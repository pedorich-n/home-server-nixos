{ lib, pkgs-unstable, ... }:
let
  package = pkgs-unstable.restic;
in
{
  options = {
    # See https://discourse.nixos.org/t/how-can-i-configure-default-values-lib-mkdefault-for-options-in-a-submodule-option/42100/3
    # See https://github.com/NixOS/nixpkgs/issues/24653#issuecomment-292684727
    services.restic.backups = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        config = {
          package = lib.mkDefault package;
        };
      });
    };
  };

  config = {
    environment.systemPackages = [ package ];
  };
}
