{
  config,
  pkgs,
  ...
}:
let
  writeINI = (pkgs.formats.ini { }).generate;
in
{
  sops.templates."obsidian-mirror/rclone.conf" = {
    file = writeINI "obsidian-mirror-rclone.conf" {
      r2 = {
        type = "s3";
        provider = "Cloudflare";
        access_key_id = config.sops.placeholder."obsidian-mirror/access_key_id";
        secret_access_key = config.sops.placeholder."obsidian-mirror/access_key_secret";
        endpoint = config.sops.placeholder."obsidian-mirror/endpoint";
        region = "auto";
        no_check_bucket = true;
      };
    };
  };
}
