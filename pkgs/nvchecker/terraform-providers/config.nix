{ pkgs, lib, ... }:
let

  # See https://developer.hashicorp.com/terraform/registry/api-docs#list-available-versions-for-a-specific-module
  # See https://nvchecker.readthedocs.io/en/latest/usage.html#search-with-an-json-parser-jq
  mkJqSource = provider: {
    source = "jq";
    url = "https://registry.terraform.io/v1/providers/${provider}/versions";
    filter = ".versions[].version";
  };

  providers = {
    # Arr stack
    prowlarr = "devopsarr/prowlarr";
    sonarr = "devopsarr/sonarr";
    radarr = "devopsarr/radarr";
    terracurl = "devops-rob/terracurl";

    # Backblaze
    netparse = "gmeligio/netparse";
    b2 = "Backblaze/b2";
    onepassword = "1Password/onepassword";

    # Tailscale
    tailscale = "tailscale/tailscale";
  };

  config = {
    # https://nvchecker.readthedocs.io/en/latest/usage.html#configuration-files
    __config__ = {
      # This file doesn't have to exist, but the key must be defined
      oldver = "oldver.json";

      # nvchecker resolves env variables: https://github.com/lilydjwg/nvchecker/blob/d44a50c/nvchecker/core.py#L207-L208 
      newver = "\${TARGET}/output.json";
    };
  } // (lib.mapAttrs (_: provider: mkJqSource provider)) providers;

  jsonProviders = lib.mapAttrs (_: provider: { source = provider; }) providers;
in
{
  nvcheckerToml = pkgs.writers.writeTOML "nvchecker-terraform-providers.toml" config;
  providersJson = pkgs.writers.writeJSON "terraform-providers.json" jsonProviders;
}
