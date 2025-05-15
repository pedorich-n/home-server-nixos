{ pkgs, pkgs-unstable, ... }:
{
  services.cockpit = {
    enable = true;
    openFirewall = true;
    package = pkgs-unstable.cockpit;

    settings = {
      WebService = {
        AllowUnencrypted = true;
      };
    };
  };

  environment.systemPackages = [
    pkgs.cockpit-files
    pkgs.cockpit-podman
  ];
}
