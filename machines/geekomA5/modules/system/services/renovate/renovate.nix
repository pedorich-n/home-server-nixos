{ config, pkgs, ... }:
{
  systemd.services.renovate.environment = {
    LOG_LEVEL = "debug";
  };

  services.renovate = {
    enable = true;
    validateSettings = true;

    schedule = "*-*-* 05:00:00"; # Every day at 05:00;

    runtimePackages = with pkgs; [
      uv
      git
      openssh
      opentofu
      config.nix.package
    ];

    settings = {
      inherit (config.time) timezone;
      binarySource = "global"; # https://docs.renovatebot.com/self-hosted-configuration/#binarysource

      onboarding = true; # https://docs.renovatebot.com/self-hosted-configuration/#onboarding
      onboardingConfig = {
        # https://docs.renovatebot.com/self-hosted-configuration/#onboardingconfig
        "$schema" = "https://docs.renovatebot.com/renovate-schema.json";
      };

      persistRepoData = true; # https://docs.renovatebot.com/self-hosted-configuration/#persistrepodata

      # Platform settings
      autodiscover = true;
      autodiscoverTopics = [ "managed-by-renovate" ];
      labels = [
        "dependencies"
        "renovate"
      ];

      platform = "github";
      gitAuthor = "Renovate Bot <15573098+pedorich-n@users.noreply.github.com>";

      # Managers/tools/etc
      nix.enabled = true; # https://docs.renovatebot.com/modules/manager/nix/
      lockFileMaintenance.enabled = true; # https://docs.renovatebot.com/configuration-options/#lockfilemaintenance

      docker-compose.enabled = false; # https://docs.renovatebot.com/modules/manager/docker-compose/
      dockerfile.enabled = false; # https://docs.renovatebot.com/modules/manager/dockerfile/
      poetry.enabled = false; # https://docs.renovatebot.com/modules/manager/poetry/

      packageRules = [{
        # https://docs.renovatebot.com/modules/manager/terraform/#terraform-vs-opentofu
        matchDatasources = [ "terraform-provider" "terraform-module" ];
        registryUrls = [ "https://registry.opentofu.org" ];
      }];


    };

    credentials = {
      RENOVATE_TOKEN = config.sops.secrets."renovate/github_token".path;
    };
  };
}
