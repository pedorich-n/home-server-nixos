{ pkgs, ... }: {
  # List governors: `cpupower frequency-info`
  powerManagement.cpuFreqGovernor = "schedutil";

  environment.systemPackages = [ pkgs.linuxKernel.packages.linux_zen.cpupower ];
}
