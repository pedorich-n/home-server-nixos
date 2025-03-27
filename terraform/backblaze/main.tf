module "onepassword" {
  source = "../modules/onepassword"
  items  = ["Backblaze_Terraform", "Backblaze_Bucket_Names"]
}

data "b2_account_info" "info" {}

data "netparse_url" "s3_base_url" {
  url = data.b2_account_info.info.s3_api_url
}

resource "b2_bucket" "managed_buckets" {
  for_each = module.onepassword.secrets.Backblaze_Bucket_Names

  bucket_name = each.value.bucket_name
  bucket_type = "allPrivate"
  lifecycle_rules {
    # This is the translation of "Keep only the latest version of the file" from the UI.
    # Can be obtained using `b2 bucket get <name>`
    days_from_hiding_to_deleting  = 1
    days_from_uploading_to_hiding = 0
    file_name_prefix              = ""
  }
}

resource "b2_application_key" "managed_keys" {
  for_each = module.onepassword.secrets.Backblaze_Bucket_Names

  key_name = "${each.key}-restic"
  capabilities = [
    "deleteFiles",
    "listBuckets",
    "listFiles",
    "readBucketEncryption",
    "readBucketNotifications",
    "readBucketReplications",
    "readBuckets",
    "readFiles",
    "shareFiles",
    "writeBucketEncryption",
    "writeBucketNotifications",
    "writeBucketReplications",
    "writeFiles"
  ]

  bucket_id = b2_bucket.managed_buckets[each.key].bucket_id
}

resource "onepassword_item" "buckets_with_b2_info" {
  vault    = module.onepassword.vault_homelab.uuid
  title    = "Backblaze_Buckets"
  category = "secure_note"

  dynamic "section" {
    # Create a section per service/bucket
    for_each = module.onepassword.secrets.Backblaze_Bucket_Names

    content {
      label = section.key

      field {
        label = "bucket_name"
        type  = "STRING"
        value = section.value.bucket_name
      }
      field {
        label = "application_key"
        type  = "CONCEALED"
        value = b2_application_key.managed_keys[section.key].application_key
      }
      field {
        label = "application_key_id"
        type  = "CONCEALED"
        value = b2_application_key.managed_keys[section.key].application_key_id
      }
      field {
        label = "url"
        type  = "STRING"
        value = "${data.netparse_url.s3_base_url.authority}/${section.value.bucket_name}"
      }
    }
  }
}
