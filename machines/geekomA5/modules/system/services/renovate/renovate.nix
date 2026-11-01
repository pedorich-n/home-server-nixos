{
  config,
  pkgs,
  pkgs-unstable,
  ...
}:
{
  services.renovate = {
    enable = true;
    validateSettings = true;
    package = pkgs-unstable.renovate;

    schedule = "*-*-* 05,10,15,20:00:00"; # Every day 4 times a day

    runtimePackages = with pkgs; [
      uv
      python3
      openssh
      config.nix.package
    ];

    settings = {
      # Global settings
      timezone = config.time.timeZone;
      binarySource = "global"; # https://docs.renovatebot.com/self-hosted-configuration/#binarysource

      onboarding = true; # https://docs.renovatebot.com/self-hosted-configuration/#onboarding
      onboardingConfig = {
        # https://docs.renovatebot.com/self-hosted-configuration/#onboardingconfig
        "$schema" = "https://docs.renovatebot.com/renovate-schema.json";
        "extends" = [
          "github>pedorich-n/renovate-config"
        ];
      };

      # Platform settings
      autodiscover = true;
      autodiscoverTopics = [ "managed-by-renovate" ];
      labels = [
        "dependencies"
        "renovate"
      ];

      platform = "github";
      gitAuthor = "pedorich-n Renovate <224430504+pedorich-n-renovate[bot]@users.noreply.github.com>";

      allowedEnv = [
        "UV_NO_MANAGED_PYTHON"
      ];

      env = {
        UV_NO_MANAGED_PYTHON = "1";
      };

      # Managers/tools/etc
      nix.enabled = true; # Doesn't work properly, sadly
      lockFileMaintenance.enabled = true; # https://docs.renovatebot.com/configuration-options/#lockfilemaintenance
      git-submodules.enabled = true; # https://docs.renovatebot.com/modules/manager/git-submodules/

      docker-compose.enabled = false; # https://docs.renovatebot.com/modules/manager/docker-compose/
      dockerfile.enabled = false; # https://docs.renovatebot.com/modules/manager/dockerfile/
      poetry.enabled = false; # https://docs.renovatebot.com/modules/manager/poetry/

      packageRules = [
        {
          # https://docs.renovatebot.com/modules/manager/terraform/#terraform-vs-opentofu
          matchDatasources = [
            "terraform-provider"
            "terraform-module"
          ];
          registryUrls = [ "https://registry.opentofu.org" ];
        }
      ];
    };
  };
}
