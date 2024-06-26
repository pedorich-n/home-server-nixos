{ config, ... }:
let
  entryFor = source: target: {
    name = "/mnt/store/home-automation/homeassistant/${target}";
    value = {
      inherit source;
      user = config.users.users.user.name;
      group = config.users.users.user.group;
    };
  };
in
{
  environment.mutable-files = builtins.listToAttrs [
    (entryFor ./automations.yaml "automations.yaml")
    (entryFor ./configuration.yaml "configuration.yaml")
    (entryFor ./ui_lovelace_minimalist/custom_cards/custom_card_humidifier/custom_card_humidifier.yaml "ui_lovelace_minimalist/custom_cards/custom_card_humidifier/custom_card_humidifier.yaml")
    (entryFor ./ui_lovelace_minimalist/dashboard/views/ui-lovelace-custom-grid-templated.yaml "ui_lovelace_minimalist/dashboard/views/ui-lovelace-custom-grid-templated.yaml")
    (entryFor ./ui_lovelace_minimalist/dashboard/ui-lovelace-custom-grid.yaml "ui_lovelace_minimalist/dashboard/ui-lovelace-custom-grid.yaml")
    (entryFor ./custom_components/smartir/codes/climate/17000.json "custom_components/smartir/codes/climate/17000.json")
  ];
}
