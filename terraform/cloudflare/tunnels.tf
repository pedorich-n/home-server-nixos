resource "random_id" "tunnel_secret" {
  for_each    = toset(["n8n", "couchdb", "safebucket"])
  byte_length = 35
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "n8n" {
  account_id    = local.cf_account_id
  name          = "N8N"
  config_src    = "cloudflare"
  tunnel_secret = random_id.tunnel_secret["n8n"].b64_std
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "n8n" {
  account_id = local.cf_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.n8n.id

  config = {
    ingress = [
      {
        hostname = local.n8n_local_domain
        path     = "/webhook(?:\\-test)?"
        service  = "https://n8n.${var.local_domain}"
        origin_request = {
          http_host_header = "n8n.${var.local_domain}"
        }
      },
      {
        hostname = local.n8n_local_domain
        path     = "/rest/oauth2-credential/callback"
        service  = "https://n8n.${var.local_domain}"
        origin_request = {
          http_host_header = "n8n.${var.local_domain}"
        }
      },
      {
        service = "http_status:403"
      }
    ]
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "couchdb" {
  account_id    = local.cf_account_id
  name          = "CouchDB"
  config_src    = "cloudflare"
  tunnel_secret = random_id.tunnel_secret["couchdb"].b64_std
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "couchdb" {
  account_id = local.cf_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.couchdb.id

  config = {
    ingress = [
      {
        hostname = local.couchdb_local_domain
        service  = "https://couchdb.${var.local_domain}"
        origin_request = {
          http_host_header = "couchdb.${var.local_domain}"
        }
      },
      {
        service = "http_status:403"
      }
    ]
  }

}

resource "cloudflare_zero_trust_tunnel_cloudflared" "safebucket" {
  account_id    = local.cf_account_id
  name          = "Safebucket"
  config_src    = "cloudflare"
  tunnel_secret = random_id.tunnel_secret["safebucket"].b64_std
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "safebucket" {
  account_id = local.cf_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.safebucket.id

  config = {
    ingress = [
      {
        hostname = local.safebucket_local_domain
        path     = "/shares/"
        service  = "https://safebucket.${var.server_domain}"
        origin_request = {
          http_host_header = "safebucket.${var.server_domain}"
        }
      },
      {
        hostname = local.safebucket_local_domain
        path     = "/assets/"
        service  = "https://safebucket.${var.server_domain}"
        origin_request = {
          http_host_header = "safebucket.${var.server_domain}"
        }
      },
      {
        hostname = local.safebucket_local_domain
        path     = "/api/v1/buckets/"
        service  = "https://safebucket.${var.server_domain}"
        origin_request = {
          http_host_header = "safebucket.${var.server_domain}"
        }
      },
      {
        service = "http_status:403"
      }
    ]
  }
}
