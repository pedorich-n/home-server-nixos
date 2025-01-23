{ config, ... }:
{
  terraform = {
    required_version = ">= 1.5";
    backend.local = { };

    required_providers = {
      inherit (config.custom.providers) sonarr radarr terracurl;
      prowlarr = {
        source = "prowlarr/prowlarr";
        version = "7.7.7";
      };
    };
  };
}
