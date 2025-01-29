{ config, pkgs, ... }:
{
  boot = {
    supportedFilesystems = {
      zfs = true;
    };

    initrd = {
      # https://gist.github.com/CMCDragonkai/810f78ee29c8fce916d072875f7e1751
      availableKernelModules = [
        "ahci" # SATA devices on modern AHCI controllers
        "sd_mod" # SCSI, SATA, and PATA (IDE) devices
        "nvme" # NVME Drives
        "sdhci_pci" # SD Card

        "usbcore" # USB modules (USB 2.0, USB 3.0, USB HID, etc)
      ];
    };

    # TODO: use linuxPackages_latest once ZFS kernel module is compatible
    kernelPackages = pkgs.linuxPackages_6_12;

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
