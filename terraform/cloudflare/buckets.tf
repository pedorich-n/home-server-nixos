resource "cloudflare_r2_bucket" "safebucket_data" {
  account_id = local.cf_account_id
  name       = "safebucket-data"
  location   = "apac"
}

resource "cloudflare_r2_bucket_cors" "safebucket_data_cors" {
  account_id  = local.cf_account_id
  bucket_name = cloudflare_r2_bucket.safebucket_data.name

  rules = [{
    id = "${cloudflare_r2_bucket.safebucket_data.name}-default"
    allowed = {
      methods = [
        "HEAD",
        "GET",
        "POST",
        "PUT",
      ]
      origins = [
        "https://safebucket.${var.domain}",
      ],
      headers = [
        "*"
      ],
      expose_headers = [
        "ETag"
      ]
    }
    max_age_seconds = 3600
  }]
}
