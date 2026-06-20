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
        credentialsFile = config.sops.secrets."cloudflared/n8n_tunnel_credentials".path;
        default = "http_status:403";
      };

      "77263f43-745d-4442-be9f-60cefd5e65ad" = {
        credentialsFile = config.sops.secrets."cloudflared/couchdb_tunnel_credentials".path;
        default = "http_status:403";
      };
    };
  };
}
