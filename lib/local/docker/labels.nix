{ config, ... }:
{
  mkTraefikLabels = { name, port, domain ? config.custom.networking.domain }: {
    "traefik.enable" = "true";
    "traefik.http.routers.${name}.rule" = "Host(`${name}.${domain}`)";
    "traefik.http.routers.${name}.entrypoints" = "web";
    "traefik.http.routers.${name}.service" = "${name}";
    "traefik.http.services.${name}.loadBalancer.server.port" = "${builtins.toString port}";
  };
}
