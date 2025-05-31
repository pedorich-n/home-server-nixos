{ lib, ... }:
{
  custom.networking.ports.udp.avahi = { port = 5353; openFirewall = true; };

  # TODO: make avahi restart if any of podmanX interfaces change. Udev rule?
  services.avahi = {
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
    ] ++ lib.map (idx: "podman${builtins.toString idx}") (lib.lists.range 0 10);
  };
}
