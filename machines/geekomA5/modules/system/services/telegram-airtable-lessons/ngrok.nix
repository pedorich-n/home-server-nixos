{ config, pkgs-unstable, ... }: {
  services.ngrok = {
    enable = true;
    package = pkgs-unstable.ngrok;
    settingsFile = config.sops.templates."ngrok.yaml".path;
  };
}
