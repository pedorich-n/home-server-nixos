{ pkgs, ... }:
let
  generateIni = filename: content: (pkgs.formats.ini { }).generate filename content;
  config = {
    containers = {
      podman_sock = "unix:///var/run/podman.sock";
    };
  };
in
generateIni "glances.conf" config
