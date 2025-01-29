{ lib, ... }:
{
  provider.tailscale = {
    api_key = lib.tfRef "local.secrets.tailscale.API.key";
  };
}
