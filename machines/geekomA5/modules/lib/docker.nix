{ config, lib, ... }: {
  config._module.args.dockerLib = {
    mkTraefikLabels =
      { name
      , domain ? "${name}.${config.custom.networking.domain}"
      , rule ? "Host(`${domain}`)"
      , priority ? 0
      , middlewares ? [ ]
      , service ? null
      , port ? null
      }: {
        "traefik.enable" = "true";
        "traefik.http.routers.${name}.rule" = "${rule}";
        "traefik.http.routers.${name}.entrypoints" = "web";
        "traefik.http.routers.${name}.service" = name;
        "traefik.http.routers.${name}.priority" = "${builtins.toString priority}";
      } // lib.optionalAttrs (middlewares != [ ]) {
        "traefik.http.routers.${name}.middlewares" = lib.concatStringsSep ", " middlewares;
      } // (if (service == null) then {
        "traefik.http.services.${name}.loadBalancer.server.port" = "${builtins.toString port}";
        "traefik.http.routers.${name}.service" = name;
      } else {
        "traefik.http.routers.${name}.service" = service;
      });

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

    mkHomepageLabels =
      { name
      , group
      , slug ? lib.toLower name
      , url-slug ? lib.replaceStrings [ "-" " " ] [ "" "" ] slug
      , href ? "http://${url-slug}.${config.custom.networking.domain}"
      , icon-slug ? slug
      , weight ? 0
      }:
      {
        "homepage.name" = name;
        "homepage.group" = group;
        "homepage.href" = href;
        "homepage.icon" = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/${icon-slug}.png";
        "homepage.weight" = "${builtins.toString weight}";
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
