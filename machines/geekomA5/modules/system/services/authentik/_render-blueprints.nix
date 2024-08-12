{ config, jinja2RendererLib }:
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
jinja2RendererLib.render-templates {
  templates = ./blueprints/sources;
  includes = [
    ./blueprints/macros
  ];
  name = "authentik-blueprints";
  inherit variables;
}
