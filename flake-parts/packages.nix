{
  flake,
  ...
}:
{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages = flake.lib.tools.flattenDerivationsTree (flake.overlays.custom-nixos-packages pkgs pkgs);
    };
}
