{
  config,
  lib,
  containerLib,
  networkingLib,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp;
  storeRoot = "/mnt/store/trawl";
in
{
  custom = {
    networking.ports.tcp = {
      trawl = {
        port = 33200;
        openFirewall = false;
      };
      trawl-mitm = {
        port = 33201;
        openFirewall = false;
      };
    };

    services.caddy.hosts.trawl = {
      upstream = "http://127.0.0.1:${portsCfg.trawl.portStr}";
    };
  };

  virtualisation.quadlet = {
    containers.trawl = {
      useGlobalContainers = true;
      usernsAuto = {
        enable = true;
        size = 65535;
      };

      containerConfig = {
        publishPorts = [
          "127.0.0.1:${portsCfg.trawl.portStr}:8191" # API, dashboard, MCP, etc
          "127.0.0.1:${portsCfg."trawl-mitm".portStr}:8192" # MITM forward proxy for Prowlarr
        ];
        environments = {
          LOG_LEVEL = "info";

          SESSION_CACHE_DRIVER = "redis";
          REDIS_URL = "redis://host.containers.internal:${toString portsCfg."redis-trawl".port}";

          MITM_ENABLED = "true";

          MCP_ENABLED = "true";
          MCP_ALLOWED_ORIGINS = lib.concatStringsSep "," [ (networkingLib.mkLocalUrl "chat") ];

          BROWSER_POOL_SIZE = "2";
          BROWSER_ACQUIRE_TIMEOUT_MS = "15000";
          BROWSER_BLOCK_ADS = "false";
          BROWSER_MAX_CONTENT_PROCESSES = "1";
          BROWSER_HARDWARE_CONCURRENCY = "4";

          METRICS_DASHBOARD_ENABLED = "false";
        };
        # Firefox uses /dev/shm heavily; without this, browser tabs crash silently.
        shmSize = "1gb";
        volumes = [
          (containerLib.mkMappedVolumeForUser storeRoot "/data")
        ];
        inherit (containerLib.containerIds) user;
      };
    };
  };
}
