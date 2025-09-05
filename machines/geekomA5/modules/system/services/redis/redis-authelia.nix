{
  config,
  ...
}:
{
  services.redis.servers."authelia" = {
    enable = true;

    unixSocketPerm = 660;
    port = 0; # Use unix socket instead

    requirePassFile = config.sops.secrets."redis/authelia/password".path;
  };
}
