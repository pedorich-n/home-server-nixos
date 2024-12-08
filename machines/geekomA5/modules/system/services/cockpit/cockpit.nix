{ pkgs, ... }:
let
  cockpitPodman = pkgs.callPackage ./_cockpit-podman.nix { };
  cockpitSensors = pkgs.callPackage ./_cockpit-sensors.nix { };
in
{
  services.cockpit = {
    enable = true;
    openFirewall = true;
  };

  environment.systemPackages = [
    cockpitPodman
    cockpitSensors
    pkgs.lm_sensors
  ];
}
