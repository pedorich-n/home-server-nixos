{ config, lib, ... }:
let
  cfg = config.custom.onepassword;

  vaultSubmodule = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.nonEmptyStr;
        description = "Name of the vault in 1Password";
      };
    };
  };

  itemSubmodule = lib.types.submodule {
    options = {
      vault = lib.mkOption {
        type = lib.types.nonEmptyStr;
        description = "Terraform name of the vault to use";
      };

      title = lib.mkOption {
        type = lib.types.nonEmptyStr;
        description = "Title of the Item too retrieve";
      };

      mapSections = lib.mkEnableOption "map sections and fields" // { default = true; };
    };
  };

  mkTfItem = _name: item: {
    vault = lib.tfRef "data.onepassword_vault.${item.vault}.uuid";
    title = item.title;
  };

  mkMappedItem = name: _item: lib.tfRef ''{ 
      for section in data.onepassword_item.${name}.section: section.label => {
        for field in section.field: field.label => field.value
      } 
    }'';


  itemsVaultsAssertion =
    let
      noVaults = lib.filterAttrs (_: item: !(lib.hasAttr item.vault cfg.vaults)) cfg.items;
      predicate = noVaults == { };
      message = lib.concatLines (lib.mapAttrsToList (name: item: "Vault '${item.vault}' for item '${name}' not found!") noVaults);
    in
    {
      inherit predicate message;
    };
in
{
  options.custom.onepassword = {
    enable = lib.mkEnableOption "1Password";

    vaults = lib.mkOption {
      type = lib.types.attrsOf vaultSubmodule;
      default = { };
    };

    items = lib.mkOption {
      type = lib.types.attrsOf itemSubmodule;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkAssert itemsVaultsAssertion.predicate itemsVaultsAssertion.message {
    terraform.required_providers = {
      inherit (config.custom.providers) onepassword;
    };

    data = {
      # https://registry.terraform.io/providers/1Password/onepassword/2.1.2/docs/data-sources/vault
      onepassword_vault = cfg.vaults;

      # https://registry.terraform.io/providers/1Password/onepassword/2.1.2/docs/data-sources/item
      onepassword_item = lib.mapAttrs mkTfItem cfg.items;
    };

    locals.secrets = lib.mapAttrs mkMappedItem (lib.filterAttrs (_: item: item.mapSections) cfg.items);
  });
}
