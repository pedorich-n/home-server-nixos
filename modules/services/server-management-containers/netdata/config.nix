{ pkgs, ... }:
let
  generateIni = filename: content: (pkgs.formats.ini { }).generate filename content;

  config = {
    # https://learn.netdata.cloud/docs/configuring/daemon-configuration
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
      "enable memory some pressure" = "no";
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
      "/proc/net/netstat" = "yes";
      "/proc/net/sctp/snmp" = "yes";
      "/proc/net/softnet_stat" = "no";
      "/proc/net/stat/conntrack" = "no";
      "/proc/diskstats" = "yes";
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
in
generateIni "netdata.conf" config
