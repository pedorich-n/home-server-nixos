{ config, ... }:
{
  boot = {
    supportedFilesystems = [ "zfs" ];

    initrd = {
      # See https://gist.github.com/CMCDragonkai/810f78ee29c8fce916d072875f7e1751
      availableKernelModules = [
        "ahci" # SATA devices on modern AHCI controllers
        "sd_mod" # SCSI, SATA, and PATA (IDE) devices
        "nvme" # NVME Drives
        "sdhci_pci" # SD Card

        "usbcore" # USB modules (USB 2.0, USB 3.0, USB HID, etc)
      ];
    };

    kernelModules = [
      "amdgpu" # AMD GPU 
      "kvm-amd" # KVM on AMD Cpus
      "k10temp" # Temperature monitoring on AMD CPUs
      "zenpower" # AMD ZEN Family CPUs current, voltage, power monitoring
      "zfs" # ZFS support
    ];
    extraModulePackages = [ config.boot.kernelPackages.zenpower ];

    kernelParams = [
      # 8GB. See https://openzfs.github.io/openzfs-docs/Performance%20and%20Tuning/Module%20Parameters.html#zfs-arc-max
      "zfs.zfs_arc_max=${builtins.toString (1024 * 1024 * 1024 * 8)}"
    ];

    loader.systemd-boot.enable = true;

    zfs = {
      forceImportRoot = false;
    };
  };
}
