resource "cloudflare_zone" "main" {
  account = {
    id = local.cf_account_id
  }
  name = local.cf_zone_domain
  type = "full"
}
