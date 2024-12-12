{ jinja2RendererLib }:
let
  variables = {
    # This one is used to group application in Authentik Dashboard
    applicationGroups = {
      serverManagement = "Server Management";
      homeAutomation = "Home Automation";
      services = "Services";
      media = "Media";
      mediaManagement = "Media Management";
    };

    # This one is for access management to applications
    accessGroups = {
      serverAdmins = "Server Admins";
      media = "Media";
      mediaAdmins = "Media Admins";
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
