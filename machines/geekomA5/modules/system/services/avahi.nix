{ config, lib, ... }:
{
  custom.networking.ports.udp.avahi = {
    port = 5353;
    openFirewall = true;
  };

  systemd.services.avahi-daemon.unitConfig = {
    # During boot, while podman containers are starting avahi gets restarted multiple times and eventually gets marked as failed.
    # This makes sure it gets restarted enough times to get going eventually.
    StartLimitBurst = 30;
    StartLimitIntervalSec = 300;
  };

  services = {
    networkd-dispatcher = {
      enable = true;
      rules = {
        "50-podman-restart-avahi" = {
          onState = [ "routable" ];
          script = ''
            if [[ "$IFACE" =~ ^podman[0-9]*$ ]]; then
                echo "Restarting avahi-daemon due to $IFACE becoming routable"
                ${lib.getExe' config.systemd.package "systemctl"} restart avahi-daemon
            fi
          '';
        };
      };
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        userServices = true;
      };
      reflector = true;

      # Avahi doesn't support prefix matching for interfaces.
      # There are multiple podmanX interfaces in my systemd, but because they are dynamic, it's impossible to know which ones are available at build time
      # Since non-existent interfaces are ignored, it's easiest to just list list "enough" interfaces here
      allowInterfaces = [
        "enp2s0"
      ]
      ++ lib.map (idx: "podman${builtins.toString idx}") (lib.lists.range 0 10);
    };
  };
}
