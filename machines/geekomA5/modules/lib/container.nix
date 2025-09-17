{
  config,
  lib,
  networkingLib,
  ...
}:
{
  _module.args.containerLib = rec {
    mkTraefikLabels =
      {
        name,
        slug ? lib.removeSuffix "-secure" name,
        domain ? networkingLib.mkDomain slug,
        entrypoints ? [ "web-secure" ],
        rule ? "Host(`${domain}`)",
        priority ? 0,
        middlewares ? [ ],
        service ? null,
        port ? null,
      }:
      [
        "traefik.enable=true"
        "traefik.http.routers.${name}.rule=${rule}"
        "traefik.http.routers.${name}.entrypoints=${lib.concatStringsSep "," entrypoints}"
        "traefik.http.routers.${name}.priority=${builtins.toString priority}"
      ]
      ++ lib.optional (middlewares != [ ]) "traefik.http.routers.${name}.middlewares=${lib.concatStringsSep "," middlewares}"
      ++ (
        if (service == null) then
          [
            "traefik.http.services.${name}.loadBalancer.server.port=${builtins.toString port}"
            "traefik.http.routers.${name}.service=${name}"
          ]
        else
          [
            "traefik.http.routers.${name}.service=${service}"
          ]
      );

    mkTraefikMetricsLabels =
      {
        name,
        port,
        addPath ? null,
        domain ? "metrics.${config.custom.networking.domain}",
      }:
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
      ]
      ++ (
        if (addPath != null) then
          [
            "traefik.http.middlewares.${replacePathMiddlewareName}.replacepath.path=${addPath}"
            "traefik.http.routers.${entityName}.middlewares=${replacePathMiddlewareName}"
          ]
        else
          [
            "traefik.http.middlewares.${stripPrefixMiddlewareName}.stripprefix.prefixes=/${name}"
            "traefik.http.routers.${entityName}.middlewares=${stripPrefixMiddlewareName}"
          ]
      );

    mkDefaultNetwork = name: {
      "${name}-internal" = {
        networkConfig.name = "${name}-internal";
      };
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
    # See https://docs.podman.io/en/stable/markdown/podman-run.1.html#mount-type-type-type-specific-option
    mkIdmappedVolume =
      {
        uidNamespace ? containerIds.uid,
        uidHost,
        uidCount ? 1,
        uidRelative ? true,
        gidNamespace ? containerIds.gid,
        gidHost,
        gidCount ? 1,
        gidRelative ? true,
      }:
      host: container:
      let
        uidPrefix = if uidRelative then "@" else "";
        gidPrefix = if gidRelative then "@" else "";

        uids = ''${uidPrefix}${builtins.toString uidHost}-${builtins.toString uidNamespace}-${builtins.toString uidCount}'';
        gids = ''${gidPrefix}${builtins.toString gidHost}-${builtins.toString gidNamespace}-${builtins.toString gidCount}'';
      in
      "${host}:${container}:idmap=uids=${uids};gids=${gids}";

    mkMappedVolumeForUser =
      localPath: remotePath:
      mkIdmappedVolume {
        uidHost = config.users.users.user.uid;
        gidHost = config.users.groups.${config.users.users.user.group}.gid;
      } localPath remotePath;

    mkMappedVolumeForUserMedia =
      localPath: remotePath:
      mkIdmappedVolume {
        uidHost = config.users.users.user.uid;
        gidHost = config.users.groups.media.gid;
      } localPath remotePath;
  };
}
