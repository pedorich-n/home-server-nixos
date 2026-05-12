{
  config,
  pkgs,
  # pkgs-unstable,
  pkgs-netdata,
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

    systemd.services.caddy.serviceConfig.SupplementaryGroups = [
      config.services.netdata.group
    ];

    services = {
      netdata = {
        enable = true;

        package = pkgs-netdata.netdataCloud.override {
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
              "!*fly_io_data_collection*" # Disable fly.io data collection alarm due to sparse metrics availability
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
          "go.d/prometheus.conf" = config.sops.templates."netdata/prometheus.conf".path;

          "go.d.conf" = pkgs.writers.writeYAML "netdata-go.d.conf" {
            modules = {
              dnsmasq = "no";
              logind = "no";
            };
          };

          "go.d/sensors.conf" = pkgs.writers.writeYAML "netdata-sensors.conf" {
            jobs = [
              {
                name = "sensors";
              }
            ];
          };
        };
      };

    };

    # alarm-notify script reads the config from /etc/netdata/health_alarm_notify.conf,
    # not from /etc/netdata/conf.d/health_alarm_notify.conf, so we can't use `configDir` option for it.
    environment.etc."netdata/health_alarm_notify.conf".source = config.sops.templates."netdata/health_alarm_notify.conf".path;
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
    users.users.${config.services.netdata.user}.extraGroups = lib.unique (lib.map (cert: cert.group) (lib.attrValues cfgCerts));

    services.netdata.configDir."go.d/x509check.conf" = pkgs.writers.writeYAML "netdata-x509check.conf" {
      update_every = 60;
      jobs = lib.map (cert: {
        name = lib.replaceStrings [ "." ] [ "_" ] cert.name;
        source = "file://${cert.value.directory}/cert.pem";
      }) (lib.attrsToList cfgCerts);
    };
  })
]
