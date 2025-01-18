let
  packages = {
    systemd-onfailure-notify = ../pkgs/systemd-onfailure-notify;
  };

  mkOverlay = name: path: _: prev: {
    ${name} = prev.callPackage path { };
  };
in
builtins.mapAttrs (name: path: mkOverlay name path) packages
