data "cloudflare_zero_trust_tunnel_cloudflared_token" "n8n" {
  account_id = local.cf_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.n8n.id
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "couchdb" {
  account_id = local.cf_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.couchdb.id
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "safebucket" {
  account_id = local.cf_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.safebucket.id
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "searxng" {
  account_id = local.cf_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.searxng.id
}

resource "cloudflare_zero_trust_access_service_token" "main" {
  name       = "Main Machine to Machine Token"
  account_id = local.cf_account_id
  duration   = "${24 * 365 * 2}h" # 2 years
}

resource "cloudflare_zero_trust_access_service_token" "obsidian_devices" {
  for_each = local.obsidian_devices

  name       = "Obsidian ${each.key} Token"
  account_id = local.cf_account_id
  duration   = "${24 * 365 * 1}h" # 1 year
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
        TunnelSecret = cloudflare_zero_trust_tunnel_cloudflared.n8n.tunnel_secret
      })
    }
  }
}

resource "cloudflare_api_token" "safebucket_data_read_write" {
  name   = "${cloudflare_r2_bucket.safebucket_data.name}-RW"
  status = "active"

  policies = [{
    effect = "allow"
    permission_groups = [
      {
        id = data.cloudflare_api_token_permission_groups_list.r2_read.result[0].id
      },
      {
        id = data.cloudflare_api_token_permission_groups_list.r2_write.result[0].id
      },
    ]
    resources = jsonencode({
      # See https://developers.cloudflare.com/r2/api/tokens/#bucket
      # "com.cloudflare.edge.r2.bucket.<ACCOUNT_ID>_<JURISDICTION>_<BUCKET_NAME>"
      "com.cloudflare.edge.r2.bucket.${local.cf_account_id}_default_${cloudflare_r2_bucket.safebucket_data.name}" = "*"
    })
  }]
}

resource "onepassword_item" "couchdb_token" {
  vault    = module.onepassword.vault_homelab.uuid
  title    = "Cloudflare_Tunnel_CouchDB"
  category = "secure_note"

  tags = ["Managed By Terraform"]

  section {
    label = "Access"

    field {
      label = "id"
      type  = "STRING"
      value = cloudflare_zero_trust_tunnel_cloudflared.couchdb.id
    }

    field {
      label = "token"
      type  = "CONCEALED"
      value = data.cloudflare_zero_trust_tunnel_cloudflared_token.couchdb.token
    }

    field {
      label = "credentials_json"
      type  = "CONCEALED"
      value = jsonencode({
        AccountTag   = local.cf_account_id
        TunnelID     = cloudflare_zero_trust_tunnel_cloudflared.couchdb.id
        TunnelSecret = cloudflare_zero_trust_tunnel_cloudflared.couchdb.tunnel_secret
      })
    }
  }
}

resource "onepassword_item" "cloudflare_service_tokens" {
  vault    = module.onepassword.vault_homelab.uuid
  title    = "Cloudflare_Service_Tokens"
  category = "secure_note"

  tags = ["Managed By Terraform"]

  section {
    label = "Main"

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

  dynamic "section" {
    for_each = local.obsidian_devices

    content {
      label = "Obsidian ${section.key}"

      field {
        label = "id"
        type  = "STRING"
        value = cloudflare_zero_trust_access_service_token.obsidian_devices[section.key].client_id
      }

      field {
        label = "token"
        type  = "CONCEALED"
        value = cloudflare_zero_trust_access_service_token.obsidian_devices[section.key].client_secret
      }
    }
  }

  section {
    label = "Searxng_MCP"

    field {
      label = "id"
      type  = "STRING"
      value = cloudflare_zero_trust_access_service_token.searxng_mcp_remote_service_token.client_id
    }

    field {
      label = "token"
      type  = "CONCEALED"
      value = cloudflare_zero_trust_access_service_token.searxng_mcp_remote_service_token.client_secret
    }
  }
}

resource "onepassword_item" "cloudflare_safebucket_data" {
  vault    = module.onepassword.vault_homelab.uuid
  title    = "Cloudflare_R2_Safebucket_Data"
  category = "secure_note"

  tags = ["Managed By Terraform"]

  section {
    label = "Metadata"

    field {
      label = "bucket_name"
      type  = "STRING"
      value = cloudflare_r2_bucket.safebucket_data.name
    }

    field {
      label = "account_domain"
      type  = "STRING"
      value = local.r2_account_domain
    }

    field {
      label = "account_url"
      type  = "URL"
      value = "https://${local.r2_account_domain}"
    }
  }

  section {
    label = "S3_API"

    field {
      label = "region"
      type  = "STRING"
      value = "auto" # See https://developers.cloudflare.com/r2/api/s3/api/#bucket-region
    }

    field {
      label = "access_key_id"
      type  = "STRING"
      value = cloudflare_api_token.safebucket_data_read_write.id
    }

    field {
      label = "access_key_secret"
      type  = "CONCEALED"
      value = sha256(cloudflare_api_token.safebucket_data_read_write.value)
    }

  }

}

resource "onepassword_item" "safebucket_token" {
  vault    = module.onepassword.vault_homelab.uuid
  title    = "Cloudflare_Tunnel_Safebucket"
  category = "secure_note"

  tags = ["Managed By Terraform"]

  section {
    label = "Access"

    field {
      label = "id"
      type  = "STRING"
      value = cloudflare_zero_trust_tunnel_cloudflared.safebucket.id
    }

    field {
      label = "token"
      type  = "CONCEALED"
      value = data.cloudflare_zero_trust_tunnel_cloudflared_token.safebucket.token
    }

    field {
      label = "credentials_json"
      type  = "CONCEALED"
      value = jsonencode({
        AccountTag   = local.cf_account_id
        TunnelID     = cloudflare_zero_trust_tunnel_cloudflared.safebucket.id
        TunnelSecret = cloudflare_zero_trust_tunnel_cloudflared.safebucket.tunnel_secret
      })
    }
  }
}

resource "onepassword_item" "searxng_token" {
  vault    = module.onepassword.vault_homelab.uuid
  title    = "Cloudflare_Tunnel_Searxng_MCP"
  category = "secure_note"

  tags = ["Managed By Terraform"]

  section {
    label = "Access"

    field {
      label = "id"
      type  = "STRING"
      value = cloudflare_zero_trust_tunnel_cloudflared.searxng.id
    }

    field {
      label = "token"
      type  = "CONCEALED"
      value = data.cloudflare_zero_trust_tunnel_cloudflared_token.searxng.token
    }

    field {
      label = "credentials_json"
      type  = "CONCEALED"
      value = jsonencode({
        AccountTag   = local.cf_account_id
        TunnelID     = cloudflare_zero_trust_tunnel_cloudflared.searxng.id
        TunnelSecret = cloudflare_zero_trust_tunnel_cloudflared.searxng.tunnel_secret
      })
    }
  }
}
