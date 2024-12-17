{ lib, ... }:
{
  provider."tailscale" = {
    api_key = lib.tfRef "var.tailscale_api_key";
  };
}
