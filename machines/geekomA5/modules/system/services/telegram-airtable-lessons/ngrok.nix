{ config, pkgs-unstable, ... }:
{
  services.ngrok = {
    enable = false;
    package = pkgs-unstable.ngrok;
    settingsFile = config.sops.templates."ngrok.yaml".path;
  };
}
