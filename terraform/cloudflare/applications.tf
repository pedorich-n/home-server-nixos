# Cloudflare Zero Trust Access Policies
resource "cloudflare_zero_trust_access_policy" "bypass_telegram_ips" {
  account_id       = local.cf_account_id
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
  account_id       = local.cf_account_id
  name             = "Deny All"
  decision         = "deny"
  session_duration = "0s"

  include = [{
    everyone = {}
  }]
}

# Cloudflare Zero Trust Access Applications
resource "cloudflare_zero_trust_access_application" "telegram_webhook" {
  zone_id          = cloudflare_zone.main.id
  name             = "Telegram Webhook"
  type             = "self_hosted"
  domain           = local.telegram_webhook_domain
  session_duration = "0s"
  policies = [
    {
      id         = cloudflare_zero_trust_access_policy.bypass_telegram_ips.id
      precedence = 1
    },
    {
      id         = cloudflare_zero_trust_access_policy.deny_all.id
      precedence = 2
    }
  ]
}
