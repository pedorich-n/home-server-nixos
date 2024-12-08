{ pkgs-unstable, ... }: {

  # disabledModules = [ "virtualisation/podman/default.nix" ];
  # imports = [ "${inputs.nixpkgs-podman}/nixos/modules/virtualisation/podman/default.nix" ];

  virtualisation.podman = {
    package = pkgs-unstable.podman;
  };
}
