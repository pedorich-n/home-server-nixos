{ config, ... }: {
  config._module.args.dockerLib = {
    mkTraefikLabels = { name, port, domain ? "${name}.${config.custom.networking.domain}" }: {
      "traefik.enable" = "true";
      "traefik.http.routers.${name}.rule" = "Host(`${domain}`)";
      "traefik.http.routers.${name}.entrypoints" = "web";
      "traefik.http.routers.${name}.service" = "${name}";
      "traefik.http.services.${name}.loadBalancer.server.port" = "${builtins.toString port}";
    };

    mkDefaultNetwork = composeName: {
      default = {
        name = "internal-${composeName}";
        internal = false;
      };
    };

    externalTraefikNetwork = {
      traefik = {
        name = "traefik";
        external = true;
      };
    };
  };
}
