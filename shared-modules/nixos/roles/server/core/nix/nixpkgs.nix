#LINK - overlays/custom-packages.nix
{ overlays, ... }: {
  nixpkgs = {
    overlays = [
      overlays.systemd-onfailure-notify
    ];
  };
}
