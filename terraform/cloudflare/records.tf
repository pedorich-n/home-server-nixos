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

resource "cloudflare_dns_record" "n8n_webhook" {
  zone_id = cloudflare_zone.main.id
  name    = local.n8n_webhook_domain
  content = "${cloudflare_zero_trust_tunnel_cloudflared.n8n_webhook.id}.cfargotunnel.com"
  type    = "CNAME"
  ttl     = 1
  proxied = true
  comment = "N8N Webhook Tunnel"
}
