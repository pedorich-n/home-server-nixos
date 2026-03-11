resource "cloudflare_zero_trust_tunnel_cloudflared" "n8n_webhook" {
  account_id    = local.cf_account_id
  name          = "N8N Webhook"
  config_src    = "cloudflare"
  tunnel_secret = module.onepassword.secrets.Cloudflare_Tunnels.N8N_Webhook.secret
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "n8n_webhook" {
  account_id = local.cf_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.n8n_webhook.id

  config = {
    ingress = [
      {
        hostname = local.n8n_webhook_domain
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
