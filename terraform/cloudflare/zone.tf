resource "cloudflare_zone" "main" {
  account = {
    id = local.cf_account_id
  }
  name = var.domain
  type = "full"
}
