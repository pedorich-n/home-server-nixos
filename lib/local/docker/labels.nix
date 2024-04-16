{ config, ... }:
{
  mkTraefikLabels = { name, port, domain ? "${name}.${config.custom.networking.domain}" }: {
    "traefik.enable" = "true";
    "traefik.http.routers.${name}.rule" = "Host(`${domain}`)";
    "traefik.http.routers.${name}.entrypoints" = "web";
    "traefik.http.routers.${name}.service" = "${name}";
    "traefik.http.services.${name}.loadBalancer.server.port" = "${builtins.toString port}";
  };
}
