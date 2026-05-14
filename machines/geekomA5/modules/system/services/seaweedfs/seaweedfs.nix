{
  config,
  lib,
  pkgs-unstable,
  systemdLib,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp;
  volumeDataRoot = "/mnt/external/seaweedfs/volumes";
  weed = lib.getExe pkgs-unstable.seaweedfs;

  commonServiceConfig = {
    User = config.users.users.seaweedfs.name;
    Group = config.users.users.seaweedfs.group;
    Restart = "on-failure";
    RestartSec = "30s";

    # Hardening
    NoNewPrivileges = true;
    PrivateTmp = true;
    PrivateDevices = true;
    ProtectHome = true;
    ProtectSystem = "strict";
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    LockPersonality = true;
    RestrictSUIDSGID = true;
    RestrictRealtime = true;
    RestrictNamespaces = true;
    RestrictAddressFamilies = [
      "AF_INET"
      "AF_INET6"
      "AF_UNIX"
    ];
  };

  withCommonConfig =
    service:
    lib.mkMerge [
      {
        serviceConfig = commonServiceConfig;
      }
      service
    ];
in
{
  custom.networking.ports.tcp = {
    seaweedfs-s3-staging = {
      port = 45002;
      openFirewall = false;
    };
    seaweedfs-master = {
      port = 45010;
      openFirewall = false;
    };
    seaweedfs-master-grpc = {
      port = 55010; # 10000 + seaweedfs-master (SeaweedFS default formula)
      openFirewall = false;
    };
    seaweedfs-volume = {
      port = 45012;
      openFirewall = false;
    };
    seaweedfs-volume-grpc = {
      port = 55012; # 10000 + seaweedfs-volume
      openFirewall = false;
    };
    seaweedfs-filer = {
      port = 45014;
      openFirewall = false;
    };
    seaweedfs-filer-grpc = {
      port = 55014; # 10000 + seaweedfs-filer
      openFirewall = false;
    };
  };

  users = {
    users.seaweedfs = {
      isSystemUser = true;
      group = "seaweedfs";
    };

    groups.seaweedfs = { };
  };

  systemd.services = {
    seaweedfs-master = withCommonConfig {
      description = "SeaweedFS Master";
      wantedBy = [
        "multi-user.target"
      ];
      unitConfig = systemdLib.requisiteAfter [
        "zfs.target"
      ];

      serviceConfig = {
        StateDirectory = "seaweedfs/master";
        WorkingDirectory = "/var/lib/seaweedfs/master";
        ExecStart = lib.concatStringsSep " " [
          weed
          "master"
          "-ip=127.0.0.1"
          "-ip.bind=127.0.0.1"
          "-mdir=/var/lib/seaweedfs/master"
          "-port=${portsCfg.seaweedfs-master.portStr}"
          "-peers=none"
          "-volumeSizeLimitMB=30000"
        ];
      };
    };

    seaweedfs-volume = withCommonConfig {
      description = "SeaweedFS Volume";
      wantedBy = [
        "multi-user.target"
      ];
      after = [
        config.systemd.services.seaweedfs-master.name
      ];

      unitConfig = systemdLib.requisiteAfter [
        "zfs.target"
      ];

      serviceConfig = {
        ReadWritePaths = [
          volumeDataRoot
        ];
        WorkingDirectory = volumeDataRoot;
        ExecStart = lib.concatStringsSep " " [
          weed
          "volume"
          "-ip=127.0.0.1"
          "-ip.bind=127.0.0.1"
          "-dir=${volumeDataRoot}"
          "-mserver=127.0.0.1:${portsCfg.seaweedfs-master.portStr}"
          "-port=${portsCfg.seaweedfs-volume.portStr}"
        ];
      };
    };

    seaweedfs-filer = withCommonConfig {
      description = "SeaweedFS Filer (S3 API)";
      wantedBy = [
        "multi-user.target"
      ];
      after = [
        config.systemd.services.seaweedfs-volume.name
      ];
      unitConfig = systemdLib.requisiteAfter [
        "zfs.target"
      ];

      serviceConfig = {
        StateDirectory = "seaweedfs/filer";
        WorkingDirectory = "/var/lib/seaweedfs/filer";
        LoadCredential = "s3-config.json:${config.sops.templates."seaweedfs/s3-config.json".path}";
        ExecStart = lib.concatStringsSep " " [
          weed
          "filer"
          "-ip=127.0.0.1"
          "-ip.bind=127.0.0.1"
          "-defaultStoreDir=/var/lib/seaweedfs/filer"
          "-master=127.0.0.1:${portsCfg.seaweedfs-master.portStr}"
          "-port=${portsCfg.seaweedfs-filer.portStr}"
          "-s3"
          "-s3.port=${portsCfg.seaweedfs-s3-staging.portStr}"
          "-s3.config=%d/s3-config.json"
        ];
      };
    };
  };
}
