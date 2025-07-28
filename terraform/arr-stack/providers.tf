terraform {
  backend "s3" {
    key = "homelab/arr-stack/terraform.tfstate"

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_s3_checksum            = true        # Not supported by B2
    region                      = "us-east-1" # Doesn't matter, since B2 doesn't support this setting

    endpoints = {
      s3 = "https://s3.us-east-005.backblazeb2.com"
    }
  }
}