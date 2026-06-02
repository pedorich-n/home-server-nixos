{
  s3Port,
  writeShellApplication,
  awscli2,
  jq,
  ...
}:
writeShellApplication {
  name = "seaweedfs-bootstrap-buckets";

  runtimeInputs = [
    awscli2
    jq
  ];

  text = ''
    config_file="$1"
    [[ -n "$config_file" ]] || { echo "Usage: seaweedfs-bootstrap-buckets <s3-config-file>" >&2; exit 1; }

    ACCESS_KEY=$(jq -r '.identities[] | select(.name == "admin") | .credentials[0].accessKey' "$config_file")
    SECRET_KEY=$(jq -r '.identities[] | select(.name == "admin") | .credentials[0].secretKey' "$config_file")

    export AWS_ENDPOINT_URL="http://127.0.0.1:${s3Port}"
    export AWS_ACCESS_KEY_ID="$ACCESS_KEY"
    export AWS_SECRET_ACCESS_KEY="$SECRET_KEY"

    until aws s3api list-buckets > /dev/null 2>&1; do
      echo "Waiting for SeaweedFS S3 API..." >&2
      sleep 2
    done

    ensure_bucket() {
      local bucket="$1"
      if ! aws s3api head-bucket --bucket "$bucket" 2>/dev/null; then
        echo "Creating bucket: $bucket" >&2
        aws s3api create-bucket --bucket "$bucket"
      else
        echo "Bucket already exists: $bucket, skipping creation." >&2
      fi
    }

    ensure_bucket grist

    # Enable versioning on grist (idempotent — Enabled is a no-op if already set)
    aws s3api put-bucket-versioning --bucket grist \
      --versioning-configuration Status=Enabled
  '';
}
