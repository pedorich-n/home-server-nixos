resource "cloudflare_zero_trust_tunnel_cloudflared" "n8n" {
  account_id    = local.cf_account_id
  name          = "N8N"
  config_src    = "cloudflare"
  tunnel_secret = module.onepassword.secrets.Cloudflare_Tunnels.N8N.secret
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "n8n" {
  account_id = local.cf_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.n8n.id

  config = {
    ingress = [
      {
        hostname = local.n8n_local_domain
        path     = "/webhook(?:\\-test)?"
        service  = "https://n8n.${var.server_domain}"
        origin_request = {
          http_host_header = "n8n.${var.server_domain}"
        }
      },
      {
        hostname = local.n8n_local_domain
        path     = "/rest/oauth2-credential/callback"
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
