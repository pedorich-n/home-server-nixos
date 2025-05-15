let
  packages = {
    systemd-onfailure-notify = ../pkgs/systemd-onfailure-notify;
    mc-monitor = ../pkgs/mc-monitor;
    minecraft-modpack = ../pkgs/minecraft-modpack;

    cockpit-files = ../pkgs/cockpit/files.nix;
    cockpit-podman = ../pkgs/cockpit/podman.nix;
  };

  mkOverlay = name: path: _: prev: {
    ${name} = prev.callPackage path { };
  };
in
builtins.mapAttrs (name: path: mkOverlay name path) packages
