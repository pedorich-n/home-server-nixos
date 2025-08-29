provider "tailscale" {
  api_key = module.onepassword.secrets.Tailscale.API.key
}
