data "cloudflare_zero_trust_tunnel_cloudflared_token" "n8n" {
  account_id = local.cf_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.n8n.id
}

resource "cloudflare_zero_trust_access_service_token" "main" {
  name       = "Machine to Machine Token"
  account_id = local.cf_account_id
  duration   = "${24 * 365 * 2}h" # 2 years
}

resource "onepassword_item" "n8n_token" {
  vault    = module.onepassword.vault_homelab.uuid
  title    = "Cloudflare_Tunnel_N8N"
  category = "secure_note"

  tags = ["Managed By Terraform"]

  section {
    label = "Access"

    field {
      label = "id"
      type  = "STRING"
      value = cloudflare_zero_trust_tunnel_cloudflared.n8n.id
    }

    field {
      label = "token"
      type  = "CONCEALED"
      value = data.cloudflare_zero_trust_tunnel_cloudflared_token.n8n.token
    }

    field {
      label = "credentials_json"
      type  = "CONCEALED"
      value = jsonencode({
        AccountTag   = local.cf_account_id
        TunnelID     = cloudflare_zero_trust_tunnel_cloudflared.n8n.id
        TunnelSecret = module.onepassword.secrets.Cloudflare_Tunnels.N8N.secret
      })
    }
  }
}

resource "onepassword_item" "cloudflare_service_token" {
  vault    = module.onepassword.vault_homelab.uuid
  title    = "Cloudflare_Service_Token"
  category = "secure_note"

  tags = ["Managed By Terraform"]

  section {
    label = "Access"

    field {
      label = "id"
      type  = "STRING"
      value = cloudflare_zero_trust_access_service_token.main.client_id
    }

    field {
      label = "token"
      type  = "CONCEALED"
      value = cloudflare_zero_trust_access_service_token.main.client_secret
    }
  }

}
