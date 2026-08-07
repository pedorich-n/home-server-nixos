resource "cloudflare_r2_bucket" "safebucket_data" {
  account_id = local.cf_account_id
  name       = "safebucket-data"
  location   = "apac"
}

resource "cloudflare_r2_bucket_cors" "safebucket_data_cors" {
  account_id  = local.cf_account_id
  bucket_name = cloudflare_r2_bucket.safebucket_data.name

  rules = [{
    allowed = {
      methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
      origins = [
        "https://files.${local.cf_zone_domain}",
        "https://files.${var.server_domain}"
      ],
      expose_headers = [
        "ETag"
      ]
    }
    id              = "${cloudflare_r2_bucket.safebucket_data.name}-default"
    max_age_seconds = 3600
  }]
}
