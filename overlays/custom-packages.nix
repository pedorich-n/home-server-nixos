let
  packages = {
    systemd-onfailure-notify = ../pkgs/systemd-onfailure-notify;
    mc-monitor = ../pkgs/mc-monitor;
    minecraft-modpack = ../pkgs/minecraft-modpack;
    prometheus-podman-exporter = ../pkgs/prometheus-podman-exporter;
  };

  mkOverlay = name: path: _: prev: {
    ${name} = prev.callPackage path { };
  };
in
builtins.mapAttrs (name: path: mkOverlay name path) packages
