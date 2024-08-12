{ jinja2RendererLib }:
jinja2RendererLib.render-templates {
  templates = ./templates/sources;
  includes = [
    ./templates/macros
  ];
  name = "home-assistant-templates";
}
