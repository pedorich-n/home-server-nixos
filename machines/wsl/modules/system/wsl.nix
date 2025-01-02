{ flake, ... }: {
  wsl = {
    enable = true;
    defaultUser = "user";
    interop.includePath = true;
    docker-desktop.enable = true;
    nativeSystemd = true;
    usbip.enable = true;

    tarball.configPath = flake;
  };
}
