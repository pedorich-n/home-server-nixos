{ flake, ... }: {
  perSystem = { pkgs, ... }: {
    devShells = {
      version-updater = pkgs.mkShellNoCC {
        name = "version-updater";

        packages = [
          pkgs.nvchecker
          pkgs.nvfetcher
        ];
      };

      tf = pkgs.mkShellNoCC {
        name = "tf";

        packages = with pkgs; [
          opentofu
          tfupdate
        ];

        env = {
          TF_VAR_server_domain = flake.nixosConfigurations.geekomA5.config.custom.networking.domain;
          TF_VAR_server_hostname = flake.nixosConfigurations.geekomA5.config.networking.hostName;
        };

        shellHook = ''
          if [ "''${CI:-false}" = "false" ]; then
            if ! [ -x "$(command -v op)" ]; then
              echo "Error: 1Password CLI (op) not found in PATH!" >&2
              exit 1
            fi

            OP_ACCOUNT=$(op account list --format=json | jq -r '.[0] | .user_uuid')
            export OP_ACCOUNT

            echo "Getting values from 1Password..."
            ITEM_PATH="op://HomeLab/Backblaze_Terraform_State/Homelab"
            TF_VAR_s3_backend_application_key=$(op read "''${ITEM_PATH}/application_key")
            TF_VAR_s3_backend_application_key_id=$(op read "''${ITEM_PATH}/application_key_id")
            TF_VAR_s3_backend_bucket=$(op read "''${ITEM_PATH}/bucket")

            export TF_VAR_s3_backend_application_key TF_VAR_s3_backend_application_key_id TF_VAR_s3_backend_bucket
          fi
        '';
      };
    };
  };
}
