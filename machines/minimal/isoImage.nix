{ modulesPath, flake, ... }: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-base.nix"
  ];

  # TODO: add inputs and more stuff to the image? See https://github.com/nix-community/disko/pull/596
  isoImage = {
    # See https://nixos.wiki/wiki/Creating_a_NixOS_live_CD#Building_faster
    # Defined in https://github.com/NixOS/nixpkgs/blob/0dca19054c663a0cf3b471be3c3079acfd623924/nixos/modules/installer/cd-dvd/iso-image.nix#L508-L521
    squashfsCompression = "gzip";

    # Defined in https://github.com/NixOS/nixpkgs/blob/0dca19054c663a0cf3b471be3c3079acfd623924/nixos/modules/installer/cd-dvd/iso-image.nix#L543-L554
    # Include this flake into the ISO so that it can be used with `nixos-install --flake /config#<machine>`
    contents = [{
      target = "/config";
      source = flake;
    }];
  };
}
