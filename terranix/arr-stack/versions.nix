{ config, ... }:
{
  terraform = {
    required_version = ">= 1.5";
    backend.local = { };

    required_providers = {
      # 1Password configured using ENV variables, see https://registry.terraform.io/providers/1Password/onepassword/2.1.2/docs#authenticate-cli-with-service-accountc
      inherit (config.custom.providers) sonarr radarr onepassword terracurl;
      prowlarr = {
        source = "prowlarr/prowlarr";
        version = "7.7.7";
      };
    };
  };
}
