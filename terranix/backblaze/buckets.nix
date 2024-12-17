{ lib, ... }:
let
  inherit (lib) tfRef;
in
{
  data = {
    # https://registry.terraform.io/providers/1Password/onepassword/2.1.2/docs/data-sources/vault
    onepassword_vault.server = {
      name = "Server";
    };

    # https://registry.terraform.io/providers/1Password/onepassword/2.1.2/docs/data-sources/item
    onepassword_item.bucket_names = {
      vault = tfRef "data.onepassword_vault.server.uuid";
      title = "Backblaze_Bucket_Names";
    };

    # https://registry.terraform.io/providers/Backblaze/b2/0.9.0/docs/data-sources/account_info
    b2_account_info.info = { };
  };

  locals = {
    b2_bucket_names = tfRef ''{ for item in data.onepassword_item.bucket_names.section: item.label => item.field[index(item.field.*.label, "bucket_name")].value }'';

    # https://registry.terraform.io/providers/gmeligio/netparse/0.0.3/docs/functions/parse_url
    s3_base_url = tfRef ''provider::netparse::parse_url(data.b2_account_info.info.s3_api_url).authority'';
  };


  resource = {
    # https://registry.terraform.io/providers/Backblaze/b2/0.9.0/docs/resources/bucket
    b2_bucket.managed_buckets = {
      for_each = tfRef "local.b2_bucket_names";
      bucket_name = tfRef "each.value";
      bucket_type = "allPrivate";
      lifecycle_rules = [{
        # This is the translation of "Keep only the latest version of the file" from the UI.
        # Can be obtained using `b2 bucket get <name>`
        days_from_hiding_to_deleting = 1;
        days_from_uploading_to_hiding = 0;
        file_name_prefix = "";
      }];
    };

    # https://registry.terraform.io/providers/Backblaze/b2/0.9.0/docs/resources/application_key
    b2_application_key.managed_keys = {
      for_each = tfRef "local.b2_bucket_names";
      key_name = "\${each.key}-restic";
      capabilities = [
        "deleteFiles"
        "listBuckets"
        "listFiles"
        "readBucketEncryption"
        "readBucketNotifications"
        "readBucketReplications"
        "readBuckets"
        "readFiles"
        "shareFiles"
        "writeBucketEncryption"
        "writeBucketNotifications"
        "writeBucketReplications"
        "writeFiles"
      ];
      bucket_id = lib.tfRef "resource.b2_bucket.managed_buckets[each.key].bucket_id";
    };

    # https://registry.terraform.io/providers/1Password/onepassword/2.1.2/docs/resources/item
    onepassword_item.buckets_with_backblaze_info = {
      vault = tfRef "data.onepassword_vault.server.uuid";
      title = "Backblaze_Buckets";
      category = "secure_note";
      dynamic.section = {
        for_each = tfRef "local.b2_bucket_names";
        content = {
          label = tfRef "section.key";
          field = [
            { label = "bucket_name"; type = "STRING"; value = tfRef "section.value"; }
            { label = "application_key"; type = "CONCEALED"; value = tfRef "resource.b2_application_key.managed_keys[section.key].application_key"; }
            { label = "application_key_id"; type = "CONCEALED"; value = tfRef "resource.b2_application_key.managed_keys[section.key].application_key_id"; }
            { label = "url"; type = "STRING"; value = "\${local.s3_base_url}/\${section.value}"; }
          ];
        };
      };
    };
  };

}
