{ pkgs, ... }:
# TODO: eventually use tailscale config. See https://github.com/tailscale/tailscale/pull/10759
# https://github.com/tailscale/tailscale/issues/10869
# https://github.com/tailscale/tailscale/issues/1412
pkgs.writeScript "tailscale-entrypoint.sh" ''
  #!/bin/sh
  export TS_AUTH_KEY=$(cat /var/run/key.txt)
  /usr/local/bin/containerboot
''
