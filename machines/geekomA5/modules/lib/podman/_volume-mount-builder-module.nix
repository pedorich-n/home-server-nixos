{
  config,
  lib,
  ...
}:
# A module that creates a mapping like `"/home/user/test:/test:idmap=uids=@1000-0-1024;gids=@100-0-1024"`
# See https://docs.podman.io/en/stable/markdown/podman-run.1.html#mount-type-type-type-specific-option
let

  idMappingModule =
    type:
    lib.types.submodule {
      options = {
        idNamespace = lib.mkOption {
          type = lib.types.ints.unsigned;
          description = "The starting ${type} in the container's user namespace.";
        };

        idHost = lib.mkOption {
          type = lib.types.ints.unsigned;
          description = "The starting ${type} on the host to map to the container's ${type} namespace.";
        };

        idCount = lib.mkOption {
          type = lib.types.ints.positive;
          default = 1;
          description = "The number of ${type}s to map.";
        };

        idRelative = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "If true the ${type} mapping will be relative to the container namespace. Should be enabled if `userns` set to `auto`";
        };
      };
    };

  mkIDMappingString =
    {
      idNamespace,
      idHost,
      idCount,
      idRelative,
    }:
    "${if idRelative then "@" else ""}${builtins.toString idHost}-${builtins.toString idNamespace}-${builtins.toString idCount}";

in
{
  options = {
    hostPath = lib.mkOption {
      type = lib.types.path;
      description = "The host path for mount that need idmapping.";
    };

    containerPath = lib.mkOption {
      type = lib.types.path;
      description = "The container path for mount that need idmapping.";
    };

    uidMappings = lib.mkOption {
      type = lib.types.listOf (idMappingModule "UID");
      description = "List of UID mappings for the container.";
      default = [ ];
    };

    gidMappings = lib.mkOption {
      type = lib.types.listOf (idMappingModule "GID");
      description = "List of GID mappings for the container.";
      default = [ ];
    };

    result = {
      uids = lib.mkOption {
        type = lib.types.str;
        description = "The resulting idmap string for podman UIDs";
        readOnly = true;
        internal = true;
      };

      gids = lib.mkOption {
        type = lib.types.str;
        description = "The resulting idmap string for podman GIDs";
        readOnly = true;
        internal = true;
      };

      idsCombined = lib.mkOption {
        type = lib.types.str;
        description = "The resulting combined idmap string for Podman";
        readOnly = true;
        internal = true;
      };

      mountString = lib.mkOption {
        type = lib.types.str;
        description = "The resulting mount string with idmap for Podman";
        readOnly = true;
        internal = true;
      };
    };
  };

  config = {
    result = {
      uids = lib.concatMapStringsSep "#" (mapping: mkIDMappingString mapping) config.uidMappings;
      gids = lib.concatMapStringsSep "#" (mapping: mkIDMappingString mapping) config.gidMappings;
      idsCombined = lib.concatStringsSep ";" (
        lib.flatten [
          (lib.optional (config.uidMappings != [ ]) "uids=${config.result.uids}")
          (lib.optional (config.gidMappings != [ ]) "gids=${config.result.gids}")
        ]
      );
      mountString =
        let
          idmapPart = lib.optionalString (config.result.idsCombined != "") "idmap=${config.result.idsCombined}";
        in
        "${config.hostPath}:${config.containerPath}:${idmapPart}";
    };
  };
}
