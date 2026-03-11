resource "cloudflare_zero_trust_tunnel_cloudflared" "telegram_webhook" {
  account_id    = local.cf_account_id
  name          = "Telegram Webhook"
  config_src    = "cloudflare"
  tunnel_secret = module.onepassword.secrets.Cloudflare_Tunnels.Telegram_Webhook.secret
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "telegram_webhook" {
  account_id = local.cf_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.telegram_webhook.id

  config = {
    ingress = [
      {
        hostname = local.telegram_webhook_domain
        path     = "/webhook(?:\\-test)?"
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
