{
  config,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.redis-trawl;
in
{
  custom.networking.ports.tcp.redis-trawl = {
    port = 33050;
    openFirewall = false;
  };

  networking.firewall.interfaces."podman+" = {
    # Allows access to the Redis server from the container
    allowedTCPPorts = [
      portsCfg.port
    ];
  };

  services.redis.servers.trawl = {
    enable = true;

    bind = "0.0.0.0"; # Listen on all interfaces, so that it can be accessed from the container
    inherit (portsCfg) port;

    settings = {
      protected-mode = "no";
    };
  };
}
