data "cloudflare_zero_trust_tunnel_cloudflared_token" "telegram_webhook" {
  account_id = local.cf_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.telegram_webhook.id
}

resource "onepassword_item" "telegram_webhook_token" {
  vault    = module.onepassword.vault_homelab.uuid
  title    = "Cloudflare_Tunnel_Telegram_Webhook"
  category = "secure_note"

  section {
    label = "Access"

    field {
      label = "Token"
      type  = "CONCEALED"
      value = data.cloudflare_zero_trust_tunnel_cloudflared_token.telegram_webhook.token
    }

    field {
      label = "CredentialsJSON"
      type  = "CONCEALED"
      value = jsonencode({
        AccountTag   = local.cf_account_id
        TunnelID     = cloudflare_zero_trust_tunnel_cloudflared.telegram_webhook.id
        TunnelSecret = module.onepassword.secrets.Cloudflare_Tunnels.Telegram_Webhook.secret
      })
    }
  }
}
