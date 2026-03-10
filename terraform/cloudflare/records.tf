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
