{
  config,
  ...
}:
let
  MiB = 1024 * 1024;
  GiB = 1024 * MiB;

  SixteenMiB = 16 * MiB;

  sysctlRange =
    min: default: max:
    "${toString min} ${toString default} ${toString max}";
in
{
  boot = {
    supportedFilesystems = {
      zfs = true;
    };

    kernelModules = [
      "amdgpu" # AMD GPU
      "kvm-amd" # KVM on AMD Cpus
      "zenpower" # AMD ZEN Family CPUs current, voltage, power monitoring
      "amd-pstate" # AMD CPU performance scaling driver
      "zfs" # ZFS support
      "tcp_bbr" # TCP congestion control algorithm
    ];

    kernel.sysctl = {
      # Congestion Control: BBR for high-throughput, low-latency video
      "net.ipv4.tcp_congestion_control" = "bbr";
      # Fair Queuing is mandatory for BBR's pacing to work correctly
      "net.core.default_qdisc" = "fq";

      # Increase the maximum receive and send buffer sizes for TCP connections to allow for better performance with high-latency, high-bandwidth connections
      # Set to 16MiB, which is a common recommendation for high-performance networking.
      "net.core.rmem_max" = SixteenMiB;
      "net.core.wmem_max" = SixteenMiB;

      # Increase the default and maximum buffer sizes for TCP inbound connections
      # 87380 is 65536 * 1.33, which is a common recommendation for the default buffer size and takes into account the TCP/IP overhead
      "net.ipv4.tcp_rmem" = sysctlRange 4096 87380 SixteenMiB;

      # Increase the default and maximum buffer sizes for TCP outbound connections
      "net.ipv4.tcp_wmem" = sysctlRange 4096 65536 SixteenMiB;
    };

    extraModulePackages = [ config.boot.kernelPackages.zenpower ];

    # https://github.com/NixOS/nixos-hardware/blob/7b49d3967613d9aacac5b340ef158d493906ba79/common/cpu/amd/zenpower.nix#L7C7-L7C49
    blacklistedKernelModules = [ "k10temp" ];

    kernelParams = [
      # https://openzfs.github.io/openzfs-docs/Performance%20and%20Tuning/Module%20Parameters.html#zfs-arc-max
      "zfs.zfs_arc_max=${toString (8 * GiB)}"
      # https://wiki.archlinux.org/title/CPU_frequency_scaling#amd_pstate
      "amd_pstate=active"
    ];

    loader.systemd-boot.enable = true;

    zfs = {
      forceImportRoot = false;
    };
  };
}
