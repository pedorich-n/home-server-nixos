resource "cloudflare_zone" "main" {
  account = {
    id = module.onepassword.secrets.Cloudflare.Account.id
  }
  name = module.onepassword.secrets.Cloudflare.Zone_Main.domain
  type = "full"
}