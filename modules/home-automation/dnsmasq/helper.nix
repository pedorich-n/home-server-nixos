{ pkgs, ... }:
pkgs.runCommand "dnsmasq-mkdir" { } ''
  mkdir -p $out/var/run/
''
