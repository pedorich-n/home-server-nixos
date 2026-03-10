resource "cloudflare_zero_trust_tunnel_cloudflared" "telegram_webhook" {
  account_id    = module.onepassword.secrets.Cloudflare.Account.id
  name          = "Telegram Webhook"
  config_src    = "cloudflare"
  tunnel_secret = module.onepassword.secrets.Cloudflare_Tunnels.Telegram_Webhook.secret
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "telegram_webhook" {
  account_id = module.onepassword.secrets.Cloudflare.Account.id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.telegram_webhook.id

  config = {
    ingress = [
      {
        hostname = local.telegram_webhook_domain
        service  = "https://n8n.${var.server_domain}"
        origin_request = {
          http_host_header = "n8n.${var.server_domain}"
        }
      },
      {
        service = "http_status:403"
      }
    ]
  }
}
