let
  packages = {
    systemd-onfailure-notify = ../pkgs/systemd-onfailure-notify;
    mc-monitor = ../pkgs/mc-monitor;
    minecraft-modpacks.exploration = ../pkgs/minecraft-modpacks/exploration.nix;
    minecraft-modpacks.crying-obsidian = ../pkgs/minecraft-modpacks/crying-obsidian.nix;
  };

  mkOverlay = name: path: _: prev: {
    ${name} = prev.callPackage path { };
  };
in
builtins.mapAttrs (name: path: mkOverlay name path) packages
