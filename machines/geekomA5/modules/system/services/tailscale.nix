{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  #LINK - docs/tailscale_setup.md
  tailscaleMachineIp = "100.90.209.21";

  dnsmasqConfig = pkgs.writeTextFile {
    name = "tailscale-dnsmasq.conf";
    text = ''
      # resolv-file=/run/systemd/resolve/resolv.conf
      # no-resolv # Don't read from /etc/resolv.conf
      bind-dynamic
      except-interface=lo
      interface=${config.services.tailscale.interfaceName}

      address=/${config.custom.networking.domain}/${tailscaleMachineIp}
    '';
  };
in
{
  systemd = {
    # services.dnsmasq is intended to be system-wide and it changes too many things in the config,
    # so it's easier to have this "local" server running with a limited scope
    services.tailscale-dnsmasq = {
      description = "Tailscale's Dnsmasq";
      after = [
        "network.target"
        "systemd-resolved.service"
        "tailscaled.service"
      ];
      bindsTo = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.dnsmasq} --keep-in-foreground --conf-file=${dnsmasqConfig}";
        ExecReload = "${lib.getExe' pkgs.coreutils "kill"} -HUP $MAINPID";
        PrivateTmp = true;
        ProtectSystem = true;
        ProtectHome = true;
        Restart = "on-failure";
      };
    };
  };

  services.tailscale = {
    enable = true;
    package = pkgs-unstable.tailscale;
    authKeyFile = config.sops.secrets."tailscale/oauth_clients/server/secret".path;
    authKeyParameters = {
      ephemeral = false;
    };

    extraUpFlags = [
      "--ssh"
      "--advertise-tags=tag:ssh,tag:server"
    ];

    extraSetFlags = [
      "--accept-dns=false"
      "--ssh"
    ];
  };
}
