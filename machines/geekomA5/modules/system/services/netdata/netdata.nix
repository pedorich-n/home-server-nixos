{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:
let

  socketPath = "/run/netdata/netdata.sock";

  cfg = config.services.netdata;
  cfgCerts = config.security.acme.certs;
in
lib.mkMerge [
  {
    # disabledModules = [ "services/monitoring/netdata.nix" ];
    # imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/monitoring/netdata.nix" ];

    custom.services.caddy.hosts.netdata = {
      upstream = "unix/${socketPath}";
      auth = "authelia";
      authBypassPaths = [ "/mcp" ];
    };

    # Required for Caddy to bind to Netdata's socket file
    systemd.services.caddy.serviceConfig.SupplementaryGroups = [
      config.services.netdata.group
    ];

    services = {
      netdata = {
        enable = true;

        package = pkgs-unstable.netdataCloud.override {
          withNdsudo = true;
          withIpmi = false;
        };

        # https://learn.netdata.cloud/docs/configuring/daemon-configuration
        config = {
          web = {
            "bind to" = "unix:${socketPath}";
          };
          health = {
            "enabled alarms" = lib.concatStringsSep " " [
              "!*fly_io_data_collection_status*" # Disable fly.io data collection alarm due to sparse metrics availability
              "*"
            ];
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
          "health_alarm_notify.conf" = config.sops.templates."netdata/health_alarm_notify.conf".path;
          "go.d/prometheus.conf" = config.sops.templates."netdata/prometheus.conf".path;
          "go.d/httpcheck.conf" = config.sops.templates."netdata/httpcheck.conf".path;

          "go.d.conf" = pkgs.writers.writeYAML "netdata-go.d.conf" {
            modules = {
              dnsmasq = false;
              logind = false;
              sensors = true;
            };
          };

          "go.d/sensors.conf" = pkgs.writers.writeYAML "netdata-sensors.conf" {
            jobs = [
              {
                name = "sensors";
              }
            ];
          };

          # Overrides to increase the lookup window and reduce false positives
          # Based on https://github.com/netdata/netdata/blob/7aefb1fb036a00e51d/src/health/health.d/httpcheck.conf
          "health.d/httpcheck_override.conf" = pkgs.writeText "netdata-httpcheck-alert-override.conf" ''
             template: httpcheck_web_service_bad_status
                   on: httpcheck.status
                class: Workload
                 type: Web Server
            component: HTTP endpoint
               lookup: average -10m unaligned percentage of bad_status
                every: 10s
                units: %
                 warn: $this >= 10 AND $this < 40
                 crit: $this >= 40
                delay: up 2m down 5m multiplier 1.5 max 1h
              summary: HTTP check for ''${label:url} unexpected status
                 info: Percentage of HTTP responses from ''${label:url} with unexpected status in the last 10 minutes
                   to: webmaster

               template: httpcheck_web_service_timeouts
                     on: httpcheck.status
                  class: Latency
                   type: Web Server
              component: HTTP endpoint
                 lookup: average -10m unaligned percentage of timeout
                  every: 10s
                  units: %
                   warn: $this >= 10 AND $this < 40
                   crit: $this >= 40
                  delay: up 2m down 5m multiplier 1.5 max 1h
                summary: HTTP check for ''${label:url} timeouts
                   info: Percentage of timed-out HTTP requests to ''${label:url} in the last 10 minutes
                     to: webmaster
          '';
        };
      };

    };
  }

  (lib.mkIf cfg.package.withNdsudo {
    systemd.services.netdata.serviceConfig = {
      CapabilityBoundingSet = [
        "CAP_SYS_RAWIO" # Required for smartctl
      ];
    };

    services.netdata = {
      extraNdsudoPackages = with pkgs; [
        nvme-cli
        smartmontools
      ];

      configDir = {
        "go.d/nvme.conf" = pkgs.writers.writeYAML "netdata-nvme.conf" {
          jobs = [
            {
              name = "nvme";
              autodetection_retry = 30;
            }
          ];
        };

        "go.d/smartctl.conf" = pkgs.writers.writeYAML "netdata-smartctl.conf" {
          jobs = [
            {
              name = "smartctl";
              autodetection_retry = 30;
            }
          ];
        };
      };
    };
  })

  (lib.mkIf config.boot.zfs.enabled {
    services.netdata.configDir."go.d/zfs.conf" = pkgs.writers.writeYAML "netdata-zfs.conf" {
      jobs = [
        {
          name = "zfs";
          binary_path = lib.getExe' config.boot.zfs.package "zfs";
        }
      ];
    };
  })

  (lib.mkIf (cfgCerts != { }) {
    systemd.services.netdata.serviceConfig.SupplementaryGroups = lib.unique (lib.map (cert: cert.group) (lib.attrValues cfgCerts));

    services.netdata.configDir."go.d/x509check.conf" = pkgs.writers.writeYAML "netdata-x509check.conf" {
      update_every = 60;
      jobs = lib.map (cert: {
        name = lib.replaceStrings [ "." ] [ "_" ] cert.name;
        source = "file://${cert.value.directory}/cert.pem";
      }) (lib.attrsToList cfgCerts);
    };
  })
]
