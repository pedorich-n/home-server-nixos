{
  config,
  pkgs-unstable,
  ...
}:
{
  # See https://github.com/NixOS/nixpkgs/pull/454518
  # See https://github.com/tailscale/tailscale/commit/ba6ec42f6d5558d04b683755aca63f88b1f2d5fc
  networking.firewall.trustedInterfaces = [
    config.services.tailscale.interfaceName
  ];

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
