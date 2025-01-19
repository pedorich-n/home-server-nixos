{ lib, ... }:
let
  inherit (lib) tfRef;
in
{
  data = {
    # https://registry.terraform.io/providers/1Password/onepassword/2.1.2/docs/data-sources/vault
    onepassword_vault.homelab = {
      name = "HomeLab";
    };

    # https://registry.terraform.io/providers/1Password/onepassword/2.1.2/docs/data-sources/item
    onepassword_item = {
      prowlarr = {
        vault = tfRef "data.onepassword_vault.homelab.uuid";
        title = "Prowlarr";
      };

      prowlarr_indexers = {
        vault = tfRef "data.onepassword_vault.homelab.uuid";
        title = "Prowlarr_Indexers";
      };

      sonarr = {
        vault = tfRef "data.onepassword_vault.homelab.uuid";
        title = "Sonarr";
      };

      radarr = {
        vault = tfRef "data.onepassword_vault.homelab.uuid";
        title = "Radarr";
      };

      sabnzbd = {
        vault = tfRef "data.onepassword_vault.homelab.uuid";
        title = "SABNzbd";
      };
    };

  };
}
