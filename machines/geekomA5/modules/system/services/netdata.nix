{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  metricsBaseUrl = config.custom.services.caddy.metrics.host;

  # https://learn.netdata.cloud/docs/collecting-metrics/generic-collecting-metrics/prometheus-endpoint#options
  prometheusEndpoints = lib.mapAttrsToList (name: _route: {
    name = lib.replaceString "-" "_" name;
    url = "${metricsBaseUrl}/${name}";
    autodetection_retry = 60;
  }) config.custom.services.caddy.metrics.routes;

  socketPath = "/run/netdata/netdata.sock";
in
{
  # disabledModules = [ "services/monitoring/netdata.nix" ];
  # imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/monitoring/netdata.nix" ];

  custom.services.caddy.hosts.netdata = {
    upstream = "unix/${socketPath}";
    auth = "authelia";
    authBypassPaths = [ "/mcp" ];
  };

  systemd.services.caddy.serviceConfig.SupplementaryGroups = [
    config.services.netdata.group
  ];

  systemd.services.netdata.serviceConfig = {
    CapabilityBoundingSet = [
      "CAP_SYS_RAWIO" # Required for smartctl
    ];
  };

  services = {
    netdata = {
      enable = true;

      package = pkgs-unstable.netdataCloud.override {
        withNdsudo = true;
        withIpmi = false;
      };

      extraNdsudoPackages = with pkgs; [
        nvme-cli
        smartmontools
      ];

      python.extraPackages = ps: [
        ps.requests
        ps.pandas
        ps.numpy
      ];

      # https://learn.netdata.cloud/docs/configuring/daemon-configuration
      config = {
        web = {
          "bind to" = "unix:${socketPath}";
        };

        plugins = {
          "timex" = "no";
          "idlejitter" = "no";
          "netdata monitoring" = "no";
          "debugfs" = "no";
          "ioping" = "no";
          "tc" = "no";
          "freeipmi" = "no";
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

            nvme: yes
            smartctl: yes
            zfspool: yes
            sensors: yes
        '';

        "go.d/zfspool.conf" = pkgs.writeText "netdata-zfspool.conf" ''
          jobs:
            - name: zfspool
              binary_path: zpool
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

  };

  # See https://stackoverflow.com/questions/66632408/what-capabilities-can-open-proc-pid-ns-net
  # security.wrappers."cgroup-network".capabilities = lib.mkForce "cap_sys_admin+ep cap_sys_ptrace+ep cap_setuid+ep cap_sys_chroot+ep";
}
