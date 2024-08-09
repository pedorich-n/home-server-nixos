let
  packages = {
    minecraft-server-check = ../pkgs/minecraft-server-check;
    systemd-onfailure-notify = ../pkgs/systemd-onfailure-notify;
    jinja-renderer = ../pkgs/jinja-renderer/renderer.nix;
    jinja-render = ../pkgs/jinja-renderer/render.nix;
  };

  mkOverlay = name: path: _: prev: {
    ${name} = prev.callPackage path { };
  };
in
builtins.mapAttrs (name: path: mkOverlay name path) packages
