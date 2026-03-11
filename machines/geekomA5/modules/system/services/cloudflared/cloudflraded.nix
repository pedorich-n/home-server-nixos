{
  config,
  pkgs-unstable,
  ...
}:
{
  services.cloudflared = {
    enable = true;
    package = pkgs-unstable.cloudflared;

    tunnels = {
      "2baf7b93-3b0f-4f3f-ac47-e8a91ec9a290" = {
        credentialsFile = config.sops.secrets."cloudflared/tunnel_credentials".path;
        default = "http_status:403";
      };
    };
  };
}
