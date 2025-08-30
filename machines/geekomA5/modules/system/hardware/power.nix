{

  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        # cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
        governor = "powersave";
        # cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_available_preferences
        energy_performance_preference = "balance_power";

        turbo = "auto";
      };
    };
  };
}
