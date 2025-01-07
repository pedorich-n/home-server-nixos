{
  networking.firewall.interfaces."podman+" = {
    # Enables DNS resolution inside podman containers
    allowedUDPPorts = [
      53 # DNS
      5353 # mDNS
      5453 # container DNS
    ];
  };
}
