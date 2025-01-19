{ lib, ... }:
{
  # https://registry.terraform.io/providers/devopsarr/radarr/2.3.1/docs/resources/download_client_sabnzbd
  # https://registry.terraform.io/providers/devopsarr/sonarr/3.4.0/docs/resources/download_client_sabnzbd
  # https://registry.terraform.io/providers/devopsarr/prowlarr/2.4.3/docs/resources/download_client_sabnzbd
  sabnzbdDownloadClient = rec {
    enable = true;
    priority = 1;
    name = "SABnzbd";
    host = "sabnzbd";
    port = 8080;
    api_key = lib.tfRef ''local.secrets.sabnzbd["API"]["key"]'';
    use_ssl = false;
  };

  # https://registry.terraform.io/providers/devopsarr/sonarr/3.4.0/docs/resources/download_client_qbittorrent
  # https://registry.terraform.io/providers/devopsarr/radarr/2.3.1/docs/resources/download_client_qbittorrent
  # https://registry.terraform.io/providers/devopsarr/prowlarr/2.4.3/docs/resources/download_client_qbittorrent
  qBittorrentDownloadClient = {
    enable = true;
    priority = 1;
    name = "qBittorrent";
    host = "gluetun";
    port = 8080;
  };
}
