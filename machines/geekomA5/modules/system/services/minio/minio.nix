{
  config,
  pkgs-unstable,
  networkingLib,
  systemdLib,
  ...
}:
let
  portsCfg = config.custom.networking.ports;
in
{
  custom.networking.ports.tcp = {
    minio-s3 = {
      port = 45000;
      openFirewall = false;
    };
    minio-console = {
      port = 45001;
      openFirewall = false;
    };
  };

  systemd.services.minio = {
    environment = {
      MINIO_API_CORS_ALLOW_ORIGIN = "*";
    };

    unitConfig = systemdLib.requisiteAfter [
      "zfs.target"
    ];
  };

  environment.systemPackages = [
    pkgs-unstable.minio-client
  ];

  services = {
    minio = {
      enable = true;
      package = pkgs-unstable.minio;
      rootCredentialsFile = config.sops.secrets."minio/main.env".path;
      region = "ap-northeast-1";
      listenAddress = "127.0.0.1:${portsCfg.tcp.minio-s3.portStr}";
      consoleAddress = "127.0.0.1:${portsCfg.tcp.minio-console.portStr}";
      browser = false; # Disable the web browser interface
      dataDir = [
        "/mnt/external/object-storage/minio"
      ];
    };

    traefik.dynamicConfigOptions.http = {
      routers.minio-s3-secure = {
        entryPoints = [ "web-secure" ];
        rule = "Host(`${networkingLib.mkDomain "storage"}`)";
        service = "minio-s3-secure";
      };

      services.minio-s3-secure = {
        loadBalancer.servers = [ { url = "http://localhost:${portsCfg.tcp.minio-s3.portStr}"; } ];
      };
    };
  };
}
