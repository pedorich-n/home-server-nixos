{ withSystem, flake, inputs, lib, ... }:
{
  imports = [
    ./_modules/lib.nix
    ./_lib/loaders.nix
    ./_lib/builders.nix
  ];
}
