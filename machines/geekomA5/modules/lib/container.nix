{ config, lib, ... }: {
  _module.args.containerLib = rec {
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

    alpineHostsFix = {
      #NOTE - there's a bug with musl or C libs or something in alpine-based images with resolving .lan domains; 
      # dig & nslookup resolves the domain, but curl fails, and the call to OIDC discovery fails too. Providing hard-coded host seems to help.
      addHosts = [ "authentik.${config.custom.networking.domain}:192.168.10.15" ];
    };

    # UID:GID to use with `--user` or `PUID`, `GUID` inside the container. Arbitrary values.
    containerIds = rec {
      uid = 1100;
      gid = 1100;

      PUID = builtins.toString uid;
      PGID = builtins.toString gid;

      user = "${builtins.toString uid}:${builtins.toString gid}";
    };

    # Creates a mapping like `"/home/user/test:/test:idmap=uids=@1000-0-1024;gids=@100-0-1024"`
    mkIdmappedVolume =
      { uidNamespace ? containerIds.uid
      , uidHost
      , uidCount ? 1
      , uidRelative ? true
      , gidNamespace ? containerIds.gid
      , gidHost
      , gidCount ? 1
      , gidRelative ? true
      }: host: container:
      let
        uids = ''${if uidRelative then "@" else ""}${toString uidHost}-${toString uidNamespace}-${toString uidCount}'';
        gids = ''${if gidRelative then "@" else ""}${toString gidHost}-${toString gidNamespace}-${toString gidCount}'';
      in
      "${host}:${container}:idmap=uids=${uids};gids=${gids}";
  };
}
