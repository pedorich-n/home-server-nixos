{ config, pkgs, lib, ... }:
let

  tokenPath = "/run/credentials/renovate/github_app_installation_token";
in
{
  systemd.services = {
    renovate-prepare-token = {
      description = "Prepare Renovate GitHub App Installation Token";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "oneshot";
      };

      script = ''
        rm -f "${tokenPath}"
        mkdir -p "$(dirname "${tokenPath}")"

        APP_PRIVATE_KEY="$(cat "''${APP_PRIVATE_KEY_FILE}")"
        export APP_PRIVATE_KEY

        ${lib.getExe pkgs.github-app-installation-token} > "${tokenPath}"

        chmod 0600 "${tokenPath}"
        chown renovate:renovate "${tokenPath}"
      '';

      environment = {
        APP_ID = "1721542";
        APP_LOGIN = "pedorich-n";
        APP_PRIVATE_KEY_FILE = config.sops.secrets."renovate/github_app_private_key".path;
      };

    };

    renovate.unitConfig = {
      Requires = [ "renovate-prepare-token.service" ];
      After = [ "renovate-prepare-token.service" ];
    };
  };

  services.renovate.credentials = {
    RENOVATE_TOKEN = tokenPath;
  };
}
