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

  authelia = _: prev: {
    authelia = prev.authelia.overrideAttrs (_: {
      version = "4.39.15";

      src = prev.fetchFromGitHub {
        owner = "authelia";
        repo = "authelia";
        rev = "v4.39.15";
        hash = "sha256-o/gVJDahMBsczAMKt5kuA1SjtwASOd98aCiS7Tp32Dg=";
      };
      vendorHash = "sha256-iBQqBX+C/7/uAuzIFlNFo7oKzWn+CYADVWf3CDIr3aU=";
      pnpmDepsHash = "sha256-uRwSpy/aZA4hG2rEY8hlD8pXJ7lvNoIa6a3VSZuZgcs=";
    });
  };
}
