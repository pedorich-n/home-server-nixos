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
        slug ? name,
        domain ? networkingLib.mkDomain slug,
        traefikName ? "${name}-secure",
        entrypoints ? [ "web-secure" ],
        rule ? "Host(`${domain}`)",
        priority ? 0,
        middlewares ? [ ],
        service ? null,
        port ? null,
      }:
      [
        "traefik.enable=true"
        "traefik.http.routers.${traefikName}.rule=${rule}"
        "traefik.http.routers.${traefikName}.entrypoints=${lib.concatStringsSep "," entrypoints}"
        "traefik.http.routers.${traefikName}.priority=${builtins.toString priority}"
      ]
      ++ lib.optional (middlewares != [ ]) "traefik.http.routers.${traefikName}.middlewares=${lib.concatStringsSep "," middlewares}"
      ++ (
        if (service == null) then
          [
            "traefik.http.services.${traefikName}.loadBalancer.server.port=${builtins.toString port}"
            "traefik.http.routers.${traefikName}.service=${traefikName}"
          ]
        else
          [
            "traefik.http.routers.${traefikName}.service=${service}"
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

    mkIdMappedVolume = {
      # Inspired by https://github.com/viperML/wrapper-manager/blob/c936f9203217e654a6074d206505c16432edbc70/default.nix
      evalMountBuilder =
        args:
        (lib.evalModules {
          modules = [
            ./podman/_volume-mount-builder-module.nix
            args
          ];
        });
      __functor = self: args: (self.evalMountBuilder args).config.result.mountString;
    };

    mkMappedVolumeForUser =
      hostPath: containerPath:
      mkIdMappedVolume {
        inherit hostPath containerPath;
        uidMappings = [
          {
            idNamespace = containerIds.uid;
            idHost = config.users.users.user.uid;
          }
        ];
        gidMappings = [
          {
            idNamespace = containerIds.gid;
            idHost = config.users.groups.${config.users.users.user.group}.gid;
          }
        ];
      };

    mkMappedVolumeForUserMedia =
      hostPath: containerPath:
      mkIdMappedVolume {
        inherit hostPath containerPath;
        uidMappings = [
          {
            idNamespace = containerIds.uid;
            idHost = config.users.users.user.uid;
          }
        ];
        gidMappings = [
          {
            idNamespace = containerIds.gid;
            idHost = config.users.groups.media.gid;
          }
        ];
      };
  };
}
