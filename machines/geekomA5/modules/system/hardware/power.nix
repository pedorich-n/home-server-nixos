{ pkgs, ... }: {
  environment.systemPackages = [ pkgs.linuxKernel.packages.linux_zen.cpupower ];

  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        # see available governors by running: cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
        governor = "powersave";
        #  EPP: see available preferences by running: cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_available_preferences
        energy_performance_preference = "balance_power";
      };
    };
  };
}
