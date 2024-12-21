{ config, ... }:
{
  terraform = {
    required_version = ">= 1.8";
    backend.local = { };

    required_providers = {
      # B2 configured using ENV variables, see https://registry.terraform.io/providers/Backblaze/b2/0.9.0/docs#optional
      # 1Password configured using ENV variables, see https://registry.terraform.io/providers/1Password/onepassword/2.1.2/docs#authenticate-cli-with-service-accountc
      inherit (config.custom.providers) netparse b2 onepassword;
    };
  };
}
