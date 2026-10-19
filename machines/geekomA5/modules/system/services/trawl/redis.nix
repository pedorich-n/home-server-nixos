{
  config,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.redis-trawl;
in
{
  custom.networking.ports.tcp.redis-trawl = {
    port = 33250;
    openFirewall = false;
  };

  # Allows the Trawl quadlet container to reach Redis over the podman+ bridge.
  networking.firewall.interfaces."podman+" = {
    allowedTCPPorts = [
      portsCfg.port
    ];
  };

  services.redis.servers.trawl = {
    enable = true;

    # 0.0.0.0 + protected-mode no because the Trawl container reaches this
    # from the podman bridge. Same exposure profile as services/grist/redis.nix.
    bind = "0.0.0.0";
    inherit (portsCfg) port;

    settings = {
      protected-mode = "no";
    };
  };
}
