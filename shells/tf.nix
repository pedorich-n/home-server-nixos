{ pkgs, nixosConfig, ... }:
pkgs.mkShellNoCC {
  name = "tf";

  packages = with pkgs; [
    bashInteractive
    gitMinimal
    jq
    opentofu
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

      TF_CLI_ARGS_init="-backend-config=\"$ROOT/terraform/backblaze.s3.tfbackend\" -backend-config=\"access_key=''${s3_backend_application_key_id}\" -backend-config=\"secret_key=''${s3_backend_application_key}\" -backend-config=\"bucket=''${s3_backend_bucket}\""

      # Limit parallelism to 3 because 1Password CLI can't handle concurrency
      parallelism_arg="-parallelism=3"

      TF_CLI_ARGS_plan="$parallelism_arg"
      TF_CLI_ARGS_apply="$parallelism_arg"

      export TF_CLI_ARGS_init TF_CLI_ARGS_plan TF_CLI_ARGS_apply

      cd "$ROOT/terraform"
    fi
  '';
}
