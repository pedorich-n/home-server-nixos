{ self, lib, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = lib.mkDefault true;
    };

    overlays = [
      (_: prev: {
        systemd-onfailure-notify = prev.callPackage "${self}/pkgs/systemd-onfailure-notify" { };
      })
    ];
  };
}
