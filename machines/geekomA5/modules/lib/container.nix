{ config, lib, ... }: {
  _module.args.containerLib = {
    mkTraefikLabels =
      { name
      , domain ? "${name}.${config.custom.networking.domain}"
      , rule ? "Host(`${domain}`)"
      , priority ? 0
      , middlewares ? [ ]
      , service ? null
      , port ? null
      }: [
        "traefik.enable=true"
        "traefik.http.routers.${name}.rule=${rule}"
        "traefik.http.routers.${name}.entrypoints=web"
        "traefik.http.routers.${name}.service=${name}"
        "traefik.http.routers.${name}.priority=${builtins.toString priority}"
      ]
      ++ lib.optional (middlewares != [ ]) "traefik.http.routers.${name}.middlewares=${lib.concatStringsSep ", " middlewares}"
      ++ (if (service == null) then [
        "traefik.http.services.${name}.loadBalancer.server.port=${builtins.toString port}"
        "traefik.http.routers.${name}.service=${name}"
      ] else [
        "traefik.http.routers.${name}.service=${service}"
      ]);

    mkTraefikMetricsLabels = { name, port, addPath ? null, domain ? "metrics.${config.custom.networking.domain}" }:
      let
        entityName = "metrics-${name}";
        stripPrefixMiddlewareName = "metrics-stripprefix-${name}";
        replacePathMiddlewareName = "metrics-replacepath-${name}";
      in
      [
        "traefik.enable=true"
        "traefik.http.routers.${entityName}.rule=Host(`${domain}`) && Path(`/${name}`)"
        "traefik.http.routers.${entityName}.entrypoints=metrics"
        "traefik.http.routers.${entityName}.service=${entityName}"

        "traefik.http.services.${entityName}.loadBalancer.server.port=${builtins.toString port}"
      ] ++ (if (addPath != null) then [
        "traefik.http.middlewares.${replacePathMiddlewareName}.replacepath.path=${addPath}"
        "traefik.http.routers.${entityName}.middlewares=${replacePathMiddlewareName}"
      ] else [
        "traefik.http.middlewares.${stripPrefixMiddlewareName}.stripprefix.prefixes=/${name}"
        "traefik.http.routers.${entityName}.middlewares=${stripPrefixMiddlewareName}"
      ]);

    mkDefaultNetwork = name: {
      "${name}-internal" = {
        networkConfig.name = "${name}-internal";
      };
    };

    mkWithNetwork = name: cfg: cfg // {
      containerConfig = cfg.containerConfig // {
        networks = [ name ] ++ (cfg.containerConfig.networks or [ ]);
      };

      unitConfig = (cfg.unitConfig or { }) // {
        Requires = [ "${name}-network.service" ] ++ (cfg.unitConfig.Requires or [ ]);
        After = [ "${name}-network.service" ] ++ (cfg.unitConfig.After or [ ]);
      };
    };

    withAlpineHostsFix = cfg: cfg // {
      #NOTE - there's a bug with musl or C libs or something in alpine-based images with resolving .lan domains; 
      # dig & nslookup resolves the domain, but curl fails, and the call to OIDC discovery fails too. Providing hard-coded host seems to help.
      addHosts = (cfg.addHosts or [ ]) ++ [ "authentik.${config.custom.networking.domain}:192.168.10.15" ];
    };
  };
}
