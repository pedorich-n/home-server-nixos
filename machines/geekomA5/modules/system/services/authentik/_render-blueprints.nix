{ jinja2RendererLib }:
let
  variables = {
    groups = {
      serverManagement = "Server Management";
      homeAutomation = "Home Automation";
      services = "Services";
      media = "Media";
    };
  };
in
jinja2RendererLib.render-templates-with-global-macros {
  templates = ./blueprints/sources;
  includes = [
    ./blueprints/macros
  ];
  name = "authentik-blueprints";
  inherit variables;
}
