{ config, pkgs, pkgs-unstable, ... }:
let
  metricsDomain = "http://metrics.${config.custom.networking.domain}:9100";

in
{
  custom.networking.ports.tcp.netdata = { port = 19999; openFirewall = false; };

  services = {
    netdata = {
      enable = true;

      package = pkgs-unstable.netdata.override { withCloud = true; withCloudUi = true; };

      # TODO: figure out a way to run from a normal user.
      # Currently netdata fails to fetch some metrics from /proc, like
      # cgroup-network[72522]: Cannot open proc_pid_fd() file '/proc/25065/ns/net'
      user = "root";
      group = "root";

      config = {
        # https://learn.netdata.cloud/docs/configuring/daemon-configuration
        web = {
          "default port" = config.custom.networking.ports.tcp.netdata.port;
        };

        ml = {
          "enabled" = "no";
        };

        plugins = {
          "timex" = "no";
          "idlejitter" = "no";
          "netdata monitoring" = "no";
          "debugfs" = "no";
          "ioping" = "no";
        };

        "plugin:cgroups" = {
          "enable cpuacct cpu throttling" = "no";
          "enable cpuacct cpu shares" = "no";
          "enable swap memory" = "no";
          "enable cpu pressure" = "no";
          "enable memory full pressure" = "no";
        };

        "plugin:apps" = {
          "command options" = "without-users without-groups";
        };

        "plugin:proc" = {
          "/proc/sys/kernel/random/entropy_avail" = "no";
          "/proc/pressure" = "no";
          "/proc/interrupts" = "no";
          "/proc/softirqs" = "no";
          "/proc/net/softnet_stat" = "no";
          "/proc/net/stat/conntrack" = "no";
          "ipc" = "no";
        };

        "plugin:proc:/proc/stat" = {
          "cpu interrupts" = "no";
        };

        "plugin:proc:/proc/vmstat" = {
          "swap i/o" = "no";
          "disk i/o" = "no";
          "memory page faults" = "no";
          "out of memory kills" = "no";
          "transparent huge pages" = "no";
        };

        "plugin:proc:/proc/meminfo" = {
          "writeback memory" = "no";
          "slab memory" = "no";
          "hugepages" = "no";
          "memory reclaiming" = "no";
          "cma memory" = "no";
        };

        "plugin:proc:/proc/net/dev" = {
          "speed for all interfaces" = "no";
          "duplex for all interfaces" = "no";
          "mtu for all interfaces" = "no";
        };
      };

      configDir = {
        "health_alarm_notify.conf" = config.age.secrets.netdata_telegram_notify.path;

        "go.d/prometheus.conf" = pkgs.writeText "netdata-prometheus.conf" ''
          jobs:
            - name: Minecraft
              url: ${metricsDomain}/minecraft
              autodetection_retry: 60
              selector:
                deny:
                - jvm_buffer_pool*
                - jvm_memory_pool_*{pool=*"CodeHeap*"}

              # NOTE: https://github.com/immich-app/immich/blob/aac789f788c8eb0275201a895926c19625b2b54f/docker/prometheus.yml
            - name: Immich Server
              url: ${metricsDomain}/immich
              autodetection_retry: 60

            - name: Immich Microservices
              url: ${metricsDomain}/immich-microservices
              autodetection_retry: 60
        '';
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers.netdata = {
        entryPoints = [ "web" ];
        rule = "Host(`netdata.${config.custom.networking.domain}`)";
        service = "netdata";
      };

      services.netdata = {
        loadBalancer.servers = [{ url = "http://localhost:19999"; }];
      };
    };
  };

  # TODO remove once https://github.com/NixOS/nixpkgs/pull/274577 is merged
  systemd.services.netdata.path = [ pkgs.jq config.virtualisation.podman.package ];

  # users.users.netdata.extraGroups = [ "podman" ];
}
