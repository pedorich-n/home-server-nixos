{
  config,
  pkgs,
  ...
}:
{
  boot = {
    supportedFilesystems = {
      zfs = true;
    };

    # NOTE: when updating, make sure ZFS is supported by the kernel version
    # TODO: update this to 6.17 once OpenZFS supports it
    kernelPackages = pkgs.linuxPackages-rt_latest;

    kernelModules = [
      "amdgpu" # AMD GPU
      "kvm-amd" # KVM on AMD Cpus
      "zenpower" # AMD ZEN Family CPUs current, voltage, power monitoring
      "amd-pstate" # AMD CPU performance scaling driver
      "zfs" # ZFS support
    ];

    extraModulePackages = [ config.boot.kernelPackages.zenpower ];

    # https://github.com/NixOS/nixos-hardware/blob/7b49d3967613d9aacac5b340ef158d493906ba79/common/cpu/amd/zenpower.nix#L7C7-L7C49
    blacklistedKernelModules = [ "k10temp" ];

    kernelParams = [
      # 8GB
      # https://openzfs.github.io/openzfs-docs/Performance%20and%20Tuning/Module%20Parameters.html#zfs-arc-max
      "zfs.zfs_arc_max=${builtins.toString (1024 * 1024 * 1024 * 8)}"
      # https://wiki.archlinux.org/title/CPU_frequency_scaling#amd_pstate
      "amd_pstate=active"
    ];

    loader.systemd-boot.enable = true;

    zfs = {
      forceImportRoot = false;
    };
  };
}
