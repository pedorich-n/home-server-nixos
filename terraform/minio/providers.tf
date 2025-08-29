provider "minio" {
  minio_server   = "storage.${var.server_domain}"
  minio_ssl      = true
  minio_user     = module.onepassword.secrets.Minio.Root_Credentials.user
  minio_password = module.onepassword.secrets.Minio.Root_Credentials.password
}
