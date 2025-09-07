let
  packages = {
    systemd-onfailure-notify = ../pkgs/systemd-onfailure-notify;
    github-app-installation-token = ../pkgs/github-app-installation-token;
    lldap-bootstrap = ../pkgs/lldap-bootstrap;
  };

  minecraft-modpacks = {
    crying-obsidian = ../pkgs/minecraft-modpacks/crying-obsidian.nix;
    monkegeddoon = ../pkgs/minecraft-modpacks/monkegeddoon.nix;
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
(builtins.mapAttrs (name: path: mkOverlay name path) packages)
// {
  cockpit-plugins = _: prev: {
    cockpit-plugins = builtins.mapAttrs (_: path: prev.callPackage path { }) cockpit-plugins;
  };

  minecraft-modpacks = _: prev: {
    minecraft-modpacks = builtins.mapAttrs (_: path: prev.callPackage path { }) minecraft-modpacks;
  };

  dashy-ui = _: prev: {
    dashy-ui =
      let
        src = prev.fetchFromGitHub {
          owner = "pedorich-n";
          repo = "dashy";
          rev = "9ad637942592c86e16870810297913c8caeeaf8f";
          sha256 = "sha256-edsGHc6Hi306aq+TA2g5FL/ZYNfExbcgHS5PWF9O0+0=";
        };
        yarnOfflineCache = prev.fetchYarnDeps {
          yarnLock = src + "/yarn.lock";
          hash = "sha256-r36w3Cz/V7E/xPYYpvfQsdk2QXfCVDYE9OxiFNyKP2s=";
        };
      in
      prev.dashy-ui.overrideAttrs {
        version = "3.1.1-unstable-2025-09-07";
        inherit src yarnOfflineCache;
      };
  };

}
