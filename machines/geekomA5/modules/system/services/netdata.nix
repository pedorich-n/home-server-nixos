{ inputs, config, lib, pkgs, pkgs-unstable, ... }:
let
  metricsDomain = "http://metrics.${config.custom.networking.domain}:${config.custom.networking.ports.tcp.traefik-metrics.portStr}";

  # https://learn.netdata.cloud/docs/collecting-metrics/generic-collecting-metrics/prometheus-endpoint#options
  prometheusEndpoints = [
    {
      # https://github.com/immich-app/immich/blob/aac789f788c8eb0275201a895926c19625b2b54f/docker/prometheus.yml
      name = "Immich Server";
      url = "${metricsDomain}/immich";
      autodetection_retry = 60;
    }
    {
      name = "Immich Microservices";
      url = "${metricsDomain}/immich-microservices";
      autodetection_retry = 60;

    }
  ];
in
{
  disabledModules = [ "services/monitoring/netdata.nix" ];
  imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/monitoring/netdata.nix" ];

  custom.networking.ports.tcp.netdata = { port = 19999; openFirewall = false; };

  services = {
    netdata = {
      enable = true;

      package = pkgs-unstable.netdataCloud.override { withNdsudo = true; };

      extraNdsudoPackages = with pkgs; [
        nvme-cli
        smartmontools
      ];

      python.extraPackages = ps: [
        ps.requests
        ps.pandas
        ps.numpy
      ];

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
          "transparent hugepages" = "no";
          "memory reclaiming" = "no";
          "cma memory" = "no";
        };

        "plugin:proc:/proc/net/dev" = {
          "speed for all interfaces" = "no";
          "duplex for all interfaces" = "no";
          "mtu for all interfaces" = "no";
        };

        "plugin:proc:/proc/net/sockstat" = {
          "ipv4 sockets" = "no";
          "ipv4 TCP sockets" = "no";
          "ipv4 UDP sockets" = "no";
          "ipv4 UDPLITE sockets" = "no";
          "ipv4 RAW sockets" = "no";
          "ipv4 FRAG sockets" = "no";
        };

        "plugin:proc:/proc/net/sockstat6" = {
          "ipv6 TCP sockets" = "no";
          "ipv6 UDP sockets" = "no";
          "ipv6 UDPLITE sockets" = "no";
          "ipv6 RAW sockets" = "no";
          "ipv6 FRAG sockets" = "no";
        };

      };

      configDir = {
        "go.d/prometheus.conf" = pkgs.writers.writeYAML "netdata-prometheus.conf" {
          jobs = prometheusEndpoints;
        };

        "go.d.conf" = pkgs.writeText "netdata-go.d.conf" ''
          modules:
            dnsmasq: no
            logind: no
            traefik: no

            nvme: yes
            smartctl: yes
            zfspool: yes
        '';

        "go.d/zfspool.conf" = pkgs.writeText "netdata-zfspool.conf" ''
          jobs:
            - name: zfspool
              binary_path: zpool
        '';

        "go.d/sensors.conf" = pkgs.writeText "netdata-sensors.conf" ''
          jobs:
            - name: sensors
              binary_path: ${lib.getExe' pkgs.lm_sensors "sensors"}
        '';

        #SECTION - Requires ndsudo
        "go.d/nvme.conf" = pkgs.writeText "netdata-nvme.conf" ''
          jobs:
            - name: nvme
              autodetection_retry: 30
        '';
        #!SECTION
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers.netdata = {
        entryPoints = [ "web" ];
        rule = "Host(`netdata.${config.custom.networking.domain}`)";
        service = "netdata";
        middlewares = [ "authentik@docker" ];
      };

      services.netdata = {
        loadBalancer.servers = [{ url = "http://localhost:19999"; }];
      };
    };
  };

  # See https://stackoverflow.com/questions/66632408/what-capabilities-can-open-proc-pid-ns-net
  # security.wrappers."cgroup-network".capabilities = lib.mkForce "cap_sys_admin+ep cap_sys_ptrace+ep cap_setuid+ep cap_sys_chroot+ep";
}
