resource "cloudflare_dns_record" "purelymail" {
  for_each = local.purelymail_records
  zone_id  = cloudflare_zone.main.id
  ttl      = 1 # Auto
  type     = each.value.type
  name     = each.value.name
  content  = each.value.content
  priority = lookup(each.value, "priority", null)
  comment  = "purelymail"
  proxied  = false
}

resource "cloudflare_dns_record" "n8n" {
  zone_id = cloudflare_zone.main.id
  name    = local.n8n_local_domain
  content = "${cloudflare_zero_trust_tunnel_cloudflared.n8n.id}.cfargotunnel.com"
  type    = "CNAME"
  ttl     = 1
  proxied = true
  comment = "N8N"
}

resource "cloudflare_dns_record" "couchdb" {
  zone_id = cloudflare_zone.main.id
  name    = local.couchdb_local_domain
  content = "${cloudflare_zero_trust_tunnel_cloudflared.couchdb.id}.cfargotunnel.com"
  type    = "CNAME"
  ttl     = 1
  proxied = true
  comment = "CouchDB"
}

resource "cloudflare_dns_record" "safebucket" {
  zone_id = cloudflare_zone.main.id
  name    = local.safebucket_local_domain
  content = "${cloudflare_zero_trust_tunnel_cloudflared.safebucket.id}.cfargotunnel.com"
  type    = "CNAME"
  ttl     = 1
  proxied = true
  comment = "Safebucket"
}

resource "cloudflare_dns_record" "searxng" {
  zone_id = cloudflare_zone.main.id
  name    = local.searxng_local_domain
  content = "${cloudflare_zero_trust_tunnel_cloudflared.searxng.id}.cfargotunnel.com"
  type    = "CNAME"
  ttl     = 1
  proxied = true
  comment = "Searxng MCP"
}
