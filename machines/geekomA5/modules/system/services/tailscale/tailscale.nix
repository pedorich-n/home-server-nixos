{
  config,
  pkgs-unstable,
  ...
}:
{
  services.tailscale = {
    enable = true;
    package = pkgs-unstable.tailscale;
    authKeyFile = config.sops.secrets."tailscale/oauth_clients/server/secret".path;
    authKeyParameters = {
      ephemeral = false;
    };

    extraUpFlags = [
      "--ssh"
      "--advertise-tags=tag:ssh,tag:server"
      "--accept-dns=false"
    ];

    extraSetFlags = [
      "--accept-dns=false"
      "--ssh"
    ];
  };
}
