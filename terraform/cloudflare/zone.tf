data "cloudflare_zone" "main" {
  filter = {
    name = var.domain

    account = {
      id = local.cf_account_id
    }
  }
}

resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = data.cloudflare_zone.main.id
  setting_id = "always_use_https"
  value      = "on"
}
