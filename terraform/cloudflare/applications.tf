# Cloudflare Zero Trust Access Policies
resource "cloudflare_zero_trust_access_policy" "bypass_telegram_ips" {
  account_id       = local.cf_account_id
  name             = "Bypass Telegram IPs"
  decision         = "bypass"
  session_duration = "0s" # Expire immediately

  include = [
    for subnet in local.telegram_subnets : {
      ip = {
        ip = subnet
      }
    }
  ]
}

resource "cloudflare_zero_trust_access_policy" "allow_service_token" {
  account_id       = local.cf_account_id
  name             = "Allow Service Token"
  decision         = "allow"
  session_duration = "24h"

  include = [{
    service_token = {
      token_id = cloudflare_zero_trust_access_service_token.main.id
    }
  }]
}

resource "cloudflare_zero_trust_access_policy" "allow_emails" {
  account_id       = local.cf_account_id
  name             = "Allow Emails"
  decision         = "allow"
  session_duration = "24h"

  include = [
    for email in split(",", module.onepassword.secrets.Cloudflare_Tunnels.N8N.allowed_emails) : {
      email = {
        email = email
      }
    }
  ]
}

resource "cloudflare_zero_trust_access_policy" "deny_all" {
  account_id       = local.cf_account_id
  name             = "Deny All"
  decision         = "deny"
  session_duration = "0s" # Expire immediately

  include = [{
    everyone = {}
  }]
}

# Not used for anything in Terraform, but useful for manual access to the Cloudflare dashboard and API.
resource "cloudflare_zero_trust_access_policy" "bypass_all" {
  account_id       = local.cf_account_id
  name             = "Bypass All"
  decision         = "bypass"
  session_duration = "0s" # Expire immediately

  include = [{
    everyone = {}
  }]

}

# Cloudflare Zero Trust Access Applications
resource "cloudflare_zero_trust_access_application" "n8n" {
  zone_id          = cloudflare_zone.main.id
  name             = "N8N"
  type             = "self_hosted"
  domain           = local.n8n_local_domain
  session_duration = "0s" # Expire immediately
  policies = [
    {
      id         = cloudflare_zero_trust_access_policy.allow_service_token.id
      precedence = 1
    },
    {
      id         = cloudflare_zero_trust_access_policy.allow_emails.id
      precedence = 2
    },
    {
      id         = cloudflare_zero_trust_access_policy.bypass_telegram_ips.id
      precedence = 3
    },
    {
      id         = cloudflare_zero_trust_access_policy.deny_all.id
      precedence = 4
    }
  ]
}
