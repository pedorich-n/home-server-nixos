{ lib, ... }:
{
  nix.registry = lib.mkOverride 950 { }; # Use system level registries but allow overrides in users. (mkDefault already used in sharedModules)
}
