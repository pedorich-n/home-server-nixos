{ config, ... }: {
  config._module.args.dockerLib = {
    mkTraefikLabels = { name, port, domain ? "${name}.${config.custom.networking.domain}" }: {
      "traefik.enable" = "true";
      "traefik.http.routers.${name}.rule" = "Host(`${domain}`)";
      "traefik.http.routers.${name}.entrypoints" = "web";
      "traefik.http.routers.${name}.service" = "${name}";
      "traefik.http.services.${name}.loadBalancer.server.port" = "${builtins.toString port}";
    };

    mkTraefikMetricsLabels = { name, port, addPath ? null, domain ? "metrics.${config.custom.networking.domain}" }:
      let
        entityName = "metrics-${name}";
        stripPrefixMiddlewareName = "metrics-stripprefix-${name}";
        replacePathMiddlewareName = "metrics-replacepath-${name}";
      in
      {
        "traefik.enable" = "true";
        "traefik.http.routers.${entityName}.rule" = "Host(`${domain}`) && Path(`/${name}`)";
        "traefik.http.routers.${entityName}.entrypoints" = "metrics";
        "traefik.http.routers.${entityName}.service" = "${entityName}";

        "traefik.http.services.${entityName}.loadBalancer.server.port" = "${builtins.toString port}";
      } // (if (addPath != null) then {
        "traefik.http.middlewares.${replacePathMiddlewareName}.replacepath.path" = "${addPath}";
        "traefik.http.routers.${entityName}.middlewares" = "${replacePathMiddlewareName}";
      } else {
        "traefik.http.middlewares.${stripPrefixMiddlewareName}.stripprefix.prefixes" = "/${name}";
        "traefik.http.routers.${entityName}.middlewares" = "${stripPrefixMiddlewareName}";
      });

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
