{ modulesPath, ... }: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-base.nix"
  ];

  isoImage = {
    # See https://nixos.wiki/wiki/Creating_a_NixOS_live_CD#Building_faster
    squashfsCompression = "gzip";
  };

  system.stateVersion = "23.05";
}
