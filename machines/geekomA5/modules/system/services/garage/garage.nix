{ config, pkgs-unstable, networkingLib, ... }:
let
  portsCfg = config.custom.networking.ports;

in
{
  custom.networking.ports.tcp = {
    garage-rpc = { port = 3900; openFirewall = false; };
    garage-s3 = { port = 3901; openFirewall = false; };
    # garage-s3-web = { port = 3902; openFirewall = false; };
  };

  services = {
    garage = {
      enable = true;

      package = pkgs-unstable.garage;

      environmentFile = config.sops.secrets."garage/main.env".path;

      settings = {
        replication_factor = 1;
        consistency_mode = "consistent";
        db_engine = "lmdb";

        metadata_auto_snapshot_interval = "6h";

        metadata_dir = "/var/lib/garage/meta";
        data_dir = [{ path = "/mnt/external/data-library/storage/data"; capacity = "500G"; }];

        rpc_bind_addr = "127.0.0.1:${portsCfg.tcp.garage-rpc.portStr}";
        rpc_public_addr = "127.0.0.1:${portsCfg.tcp.garage-rpc.portStr}";

        s3_api = {
          api_bind_addr = "127.0.0.1:${portsCfg.tcp.garage-s3.portStr}";
          s3_region = "ap-northeast-1"; # A real region, since looks like not all S3 clients support custom regions
        };
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers.garage-s3-secure = {
        entryPoints = [ "web-secure" ];
        rule = "Host(`${networkingLib.mkDomain "storage"}`)";
        service = "garage-s3-secure";
      };

      services.garage-s3-secure = {
        loadBalancer.servers = [{ url = "http://localhost:${portsCfg.tcp.garage-s3.portStr}"; }];
      };
    };
  };
}
