{
  inputs,
  modulesPath,
  flake,
  ...
}:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-base.nix"
  ];

  isoImage = {
    # Bake every flake input's source into the ISO's /nix/store so the
    # live environment can evaluate the flake (including private inputs that cannot be fetched at runtime).
    # Only the input source paths themselves are added; their transitive closures are not.
    storeContents = builtins.attrValues (builtins.mapAttrs (_: input: input.outPath) inputs);

    # Include this flake into the ISO so that it can be used with
    # `nixos-install --flake /config#<machine>`.
    # Defined in https://github.com/NixOS/nixpkgs/blob/2787c8/nixos/modules/installer/cd-dvd/iso-image.nix#L601-L612
    contents = [
      {
        target = "/config";
        source = flake;
      }
    ];
  };
}
