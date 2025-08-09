{ lib, ... }:
{
  home.enableNixpkgsReleaseCheck = lib.mkDefault false; # Don't compare nixpkgs and HM versions
}
