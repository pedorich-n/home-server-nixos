{ config, pkgs, ... }:
let
  variables = {
    server_domain = config.custom.networking.domain;
    icons_base_url = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png";

    groups = {
      serverManagement = "Server Management";
      homeAutomation = "Home Automation";
      services = "Services";
    };
  };
in
pkgs.render-templates {
  templates = ./blueprints;
  name = "authentik-blueprints";
  inherit variables;
}
