{ pkgs-unstable, inputs, ... }: {

  disabledModules = [ "virtualisation/podman/default.nix" ];
  imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/virtualisation/podman/default.nix" ];

  virtualisation.podman = {
    package = pkgs-unstable.podman;
  };
}
