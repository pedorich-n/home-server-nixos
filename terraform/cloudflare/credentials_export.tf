data "cloudflare_zero_trust_tunnel_cloudflared_token" "n8n_webhook" {
  account_id = local.cf_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.n8n_webhook.id
}

resource "onepassword_item" "n8n_webhook_token" {
  vault    = module.onepassword.vault_homelab.uuid
  title    = "Cloudflare_Tunnel_N8N_Webhook"
  category = "secure_note"

  tags = ["Managed By Terraform"]

  section {
    label = "Access"

    field {
      label = "id"
      type  = "STRING"
      value = cloudflare_zero_trust_tunnel_cloudflared.n8n_webhook.id
    }

    field {
      label = "token"
      type  = "CONCEALED"
      value = data.cloudflare_zero_trust_tunnel_cloudflared_token.n8n_webhook.token
    }

    field {
      label = "credentials_json"
      type  = "CONCEALED"
      value = jsonencode({
        AccountTag   = local.cf_account_id
        TunnelID     = cloudflare_zero_trust_tunnel_cloudflared.n8n_webhook.id
        TunnelSecret = module.onepassword.secrets.Cloudflare_Tunnels.N8N_Webhook.secret
      })
    }
  }
}
