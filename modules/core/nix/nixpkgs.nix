#LINK - overlays/custom-packages.nix
{ overlays, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };

    overlays = [
      overlays.systemd-onfailure-notify
    ];
  };
}
