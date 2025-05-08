{ config, ... }: {
  boot.initrd = {
    availableKernelModules = [
      "r8169" # Ethernet. Detected with `lspci -v`
    ];

    network.ssh.hostKeys = [
      "/etc/initrd/ssh/ssh_host_rsa_key"
      "/etc/initrd/ssh/ssh_host_ed25519_key"
    ];
    systemd = {
      enable = true;

      network.networks."10-uplink" = config.systemd.network.networks."10-uplink";
    };
  };

  custom.boot.initrd.network.tailscale = {
    enable = true;

    authKeyFile = config.sops.secrets."tailscale/initrd_key".path;
  };
}
