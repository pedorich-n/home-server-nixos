{ pkgs, ... }: {
  environment.systemPackages = [ pkgs.linuxKernel.packages.linux_zen.cpupower ];

  # List governors: `cpupower frequency-info`
  powerManagement.cpuFreqGovernor = "schedutil";
}
