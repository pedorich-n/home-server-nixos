{ pkgs, config, ... }:
let
  generateIni = filename: content: (pkgs.formats.ini { }).generate filename content;

  mainConfig = {
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

  # TODO: figuire out a way to access host from inside the netdata podman container instead of accessing it via local network
  prometheusConfig = ''
    jobs:
      - name: Minecraft
        url: http://192.168.15.10:${toString config.custom.shared-config.ports.minecraft-money-guys-4.tcp.metrics.port}/metrics
        selector:
          deny:
           - jvm_buffer_pool*
           - jvm_memory_pool_*{pool=*"CodeHeap*"}
  '';
in
{
  main = generateIni "netdata.conf" mainConfig;
  prometheus = pkgs.writeText "netdata-prometheus.conf" prometheusConfig;
}
