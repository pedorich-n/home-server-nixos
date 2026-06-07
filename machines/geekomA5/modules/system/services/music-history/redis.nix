{
  config,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.redis-multiscrobbler;
in
{
  custom.networking.ports.tcp = {
    redis-multiscrobbler = {
      port = 30250;
      openFirewall = false;
    };
  };

  networking.firewall.interfaces."podman+" = {
    # Allows access to the Redis server from the container
    allowedTCPPorts = [
      portsCfg.port
    ];
  };

  services.redis.servers.multiscrobbler = {
    enable = true;

    bind = "0.0.0.0"; # Listen on all interfaces, so that it can be accessed from the container
    inherit (portsCfg) port;

    settings = {
      protected-mode = "no";
    };
  };
}
