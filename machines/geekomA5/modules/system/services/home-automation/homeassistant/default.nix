{ config, jinja2RendererLib, ... }:
let
  entryFor = source: target: {
    name = "/mnt/store/home-automation/homeassistant/${target}";
    value = {
      inherit source;
      user = config.users.users.user.name;
      group = config.users.users.user.group;
    };
  };

  rendered-templates = import ./_render-templates.nix { inherit jinja2RendererLib; };
in
{
  environment.mutable-files = builtins.listToAttrs [
    (entryFor ./static/automations.yaml "automations.yaml")
    (entryFor ./static/configuration.yaml "configuration.yaml")
    (entryFor ./static/ui_lovelace_minimalist/custom_cards/custom_card_humidifier/custom_card_humidifier.yaml "ui_lovelace_minimalist/custom_cards/custom_card_humidifier/custom_card_humidifier.yaml")
    (entryFor ./static/custom_components/smartir/codes/climate/17000.json "custom_components/smartir/codes/climate/17000.json")
    # (entryFor ./static/ui_lovelace_minimalist/dashboard/views/ui-lovelace-custom-grid-templated.yaml "ui_lovelace_minimalist/dashboard/views/ui-lovelace-custom-grid-templated.yaml")
    (entryFor "${rendered-templates}/ui_lovelace_minimalist/dashboard/ui-lovelace-custom-grid.yaml" "ui_lovelace_minimalist/dashboard/ui-lovelace-custom-grid.yaml")
  ];
}
