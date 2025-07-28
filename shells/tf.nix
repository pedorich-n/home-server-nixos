{ pkgs, nixosConfig, ... }:
pkgs.mkShellNoCC {
  name = "tf";

  packages = with pkgs; [
    gitMinimal
    jq
    opentofu
    tfupdate
  ];

  env = {
    TF_VAR_server_domain = nixosConfig.config.custom.networking.domain;
    TF_VAR_server_hostname = nixosConfig.config.networking.hostName;
  };

  shellHook = ''
    if [ "''${CI:-false}" = "false" ]; then
      if ! [ -x "$(command -v op)" ]; then
        echo "Error: 1Password CLI (op) not found in PATH!" >&2
        exit 1
      fi

      ROOT="$(git rev-parse --show-toplevel)"
      export ROOT

      OP_ACCOUNT=$(op account list --format=json | jq -r '.[0] | .user_uuid')
      export OP_ACCOUNT

      echo "Getting values from 1Password..."
      item_json=$(op item get "Backblaze_Terraform_State" --vault "HomeLab" --format json)

      s3_backend_application_key=$(echo "$item_json" | jq -r '.fields[] | select(.label == "application_key") | .value')
      s3_backend_application_key_id=$(echo "$item_json" | jq -r '.fields[] | select(.label == "application_key_id") | .value')
      s3_backend_bucket=$(echo "$item_json" | jq -r '.fields[] | select(.label == "bucket") | .value')

      TF_CLI_ARGS_init="-backend-config=\"access_key=''${s3_backend_application_key_id}\" -backend-config=\"secret_key=''${s3_backend_application_key}\" -backend-config=\"bucket=''${s3_backend_bucket}\""

      export TF_CLI_ARGS_init

      cd "$ROOT/terraform"
    fi
  '';
}
