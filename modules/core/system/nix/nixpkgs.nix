{ self, lib, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = lib.mkDefault true;
    };

    overlays = [
      (_: prev: {
        # TODO: investigate if it's better to pass the package as an argument
        systemd-onfailure-notify = prev.callPackage "${self}/pkgs/systemd-onfailure-notify" { };
      })
    ];
  };
}
