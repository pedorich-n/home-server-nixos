module "onepassword" {
  source = "../modules/onepassword"
  items  = ["Minio"]
}

resource "minio_iam_user" "ente_photos" {
  name = "ente-photos"
}

resource "minio_s3_bucket" "ente_photos" {
  bucket = module.onepassword.secrets.Minio.Ente_Photos.bucket_name
  acl    = "public"
}

resource "minio_iam_policy" "ente_photos_policy" {
  name   = "ente-photos-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetBucketLocation",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": "${minio_s3_bucket.ente_photos.arn}"
    },
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Effect": "Allow",
      "Resource": "${minio_s3_bucket.ente_photos.arn}/*"
    }
  ]
}
EOF
}

resource "minio_iam_user_policy_attachment" "ente_photos_policy_attachment" {
  user_name   = minio_iam_user.ente_photos.id
  policy_name = minio_iam_policy.ente_photos_policy.id
}

resource "minio_accesskey" "ente-photos-key" {
  user       = minio_iam_user.ente_photos.name
  access_key = module.onepassword.secrets.Minio.Ente_Photos.access_key
  secret_key = module.onepassword.secrets.Minio.Ente_Photos.secret_key
  status     = "enabled"
}