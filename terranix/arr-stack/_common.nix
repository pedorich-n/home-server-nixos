{
  # Schema: https://registry.terraform.io/providers/devopsarr/radarr/2.3.1/docs/resources/download_client_sabnzbd
  # Schema: https://registry.terraform.io/providers/devopsarr/sonarr/3.3.0/docs/resources/download_client_sabnzbd
  sabnzbdDownloadClient = rec {
    enable = true;
    priority = 1;
    name = "SABnzbd";
    host = "sabnzbd";
    port = 8080;
    api_key = "\${var.downloaders[\"${name}\"]}";
    use_ssl = false;
  };
}
