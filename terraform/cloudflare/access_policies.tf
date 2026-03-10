resource "cloudflare_zero_trust_access_policy" "bypass_telegram_ips" {
  account_id       = module.onepassword.secrets.Cloudflare.Account.id
  name             = "Bypass Telegram IPs"
  decision         = "bypass"
  session_duration = "0s"

  include = [
    for subnet in local.telegram_webhook_subnets : {
      ip = {
        ip = subnet
      }
    }
  ]
}

resource "cloudflare_zero_trust_access_policy" "deny_all" {
  account_id       = module.onepassword.secrets.Cloudflare.Account.id
  name             = "Deny All"
  decision         = "deny"
  session_duration = "0s"

  include = [{
    everyone = {}
  }]
}