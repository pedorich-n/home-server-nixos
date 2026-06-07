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

  services.redis.servers.multiscrobbler = {
    enable = true;

    bind = "127.0.0.1";
    inherit (portsCfg) port;
  };
}
