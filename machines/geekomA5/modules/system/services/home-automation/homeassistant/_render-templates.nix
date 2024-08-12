{ jinja2RendererLib }:
jinja2RendererLib.render-templates-with-global-macros {
  templates = ./templates/sources;
  includes = [
    ./templates/macros
  ];
  name = "home-assistant-templates";
}
