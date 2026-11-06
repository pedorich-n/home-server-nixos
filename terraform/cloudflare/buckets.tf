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
    }
    expose_headers = [
      "ETag"
    ]
    max_age_seconds = 3600
  }]
}

resource "cloudflare_r2_bucket" "obsidian_vault" {
  account_id = local.cf_account_id
  name       = "obsidian-vault"
  location   = "apac"
}

resource "cloudflare_r2_bucket_cors" "obsidian_vault_cors" {
  account_id  = local.cf_account_id
  bucket_name = cloudflare_r2_bucket.obsidian_vault.name

  rules = [{
    id = "${cloudflare_r2_bucket.obsidian_vault.name}-default"
    allowed = {
      methods = [
        "HEAD",
        "GET",
        "POST",
        "PUT",
        "DELETE",
      ]
      # Obsidian's webview origins.
      # LINK - .slim/plan/obsidian-sync-r2/notes.md
      origins = [
        "app://obsidian.md",
        "capacitor://localhost",
        "http://localhost",
      ]
      headers = [
        "*"
      ]
    }
    # LiveSync uploads conditionally with If-Match on the ETag; without this the
    # browser cannot read it and conditional updates degrade.
    expose_headers = [
      "ETag"
    ]
    max_age_seconds = 3600
  }]
}
