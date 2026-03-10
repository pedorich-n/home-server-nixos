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

resource "cloudflare_dns_record" "telegram_webhook" {
  zone_id = cloudflare_zone.main.id
  name    = module.onepassword.secrets.Cloudflare_Tunnels.Telegram_Webhook.subdomain
  content = "${cloudflare_zero_trust_tunnel_cloudflared.telegram_webhook.id}.cfargotunnel.com"
  type    = "CNAME"
  ttl     = 1
  proxied = true
  comment = "Telegram Webhook Tunnel"
}