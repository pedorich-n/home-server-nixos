{ pkgs, ... }:
pkgs.writeScript "tailscale-entrypoint.sh" ''
  #!/bin/sh
  export TS_AUTH_KEY=$(cat /var/run/key.txt)
  /usr/local/bin/containerboot
''
