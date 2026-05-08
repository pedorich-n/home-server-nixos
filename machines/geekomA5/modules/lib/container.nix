{
  config,
  lib,

  ...
}:
{
  _module.args.containerLib = rec {
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
