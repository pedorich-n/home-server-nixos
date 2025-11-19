module "onepassword" {
  source = "../modules/onepassword"
  items  = ["Minio", "Minio_Buckets"]
}

resource "minio_iam_user" "users" {
  for_each = module.onepassword.secrets.Minio_Buckets
  name     = each.value.bucket_name
}

resource "minio_s3_bucket" "buckets" {
  for_each = module.onepassword.secrets.Minio_Buckets
  bucket   = each.value.bucket_name
  acl      = "private"
}

resource "minio_iam_policy" "buckets_policy" {
  for_each = module.onepassword.secrets.Minio_Buckets

  name   = "${each.value.bucket_name}-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:GetBucketVersioning",
        "s3:ListBucketVersions",
        "s3:ListBucketMultipartUploads"
      ],
      "Effect": "Allow",
      "Resource": "${minio_s3_bucket.buckets[each.key].arn}"
    },
    {
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts"
      ],
      "Effect": "Allow",
      "Resource": "${minio_s3_bucket.buckets[each.key].arn}/*"
    }
  ]
}
EOF
}

resource "minio_iam_user_policy_attachment" "buckets_policy_attachment" {
  for_each = module.onepassword.secrets.Minio_Buckets

  user_name   = minio_iam_user.users[each.key].id
  policy_name = minio_iam_policy.buckets_policy[each.key].id
}

resource "minio_accesskey" "access_keys" {
  for_each = module.onepassword.secrets.Minio_Buckets

  user               = minio_iam_user.users[each.key].name
  access_key         = module.onepassword.secrets.Minio_Buckets[each.key].access_key
  secret_key         = module.onepassword.secrets.Minio_Buckets[each.key].secret_key
  secret_key_version = sha256(module.onepassword.secrets.Minio_Buckets[each.key].secret_key)
  status             = "enabled"
}

resource "minio_s3_bucket_versioning" "grist_versioning" {
  bucket = module.onepassword.secrets.Minio_Buckets["Grist"].bucket_name

  versioning_configuration {
    status = "Enabled"
  }
}