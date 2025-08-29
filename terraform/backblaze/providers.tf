provider "b2" {
  application_key_id = module.onepassword.secrets.Backblaze_Terraform.API.application_key_id
  application_key    = module.onepassword.secrets.Backblaze_Terraform.API.application_key
}
