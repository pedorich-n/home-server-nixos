let
  packages = {
    systemd-onfailure-notify = ../pkgs/systemd-onfailure-notify;
  };

  minecraft-modpacks = {
    crying-obsidian = ../pkgs/minecraft-modpacks/crying-obsidian.nix;
  };

  cockpit-plugins = {
    files = ../pkgs/cockpit-plugins/files.nix;
    podman = ../pkgs/cockpit-plugins/podman.nix;
  };

  mkOverlay = name: path: _: prev: {
    ${name} = prev.callPackage path { };
  };
in
# TODO: figure out a nicer way to do this. See https://noogle.dev/f/lib/filesystem/packagesFromDirectoryRecursive for inspiration
(builtins.mapAttrs (name: path: mkOverlay name path) packages) //
{
  cockpit-plugins = _: prev: {
    cockpit-plugins = builtins.mapAttrs (_: path: prev.callPackage path { }) cockpit-plugins;
  };

  minecraft-modpacks = _: prev: {
    minecraft-modpacks = builtins.mapAttrs (_: path: prev.callPackage path { }) minecraft-modpacks;
  };
}
