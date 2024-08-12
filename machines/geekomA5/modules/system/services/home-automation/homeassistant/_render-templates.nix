{ jinja2RendererLib }:
jinja2RendererLib.render-templates {
  templates = ./templates/source;
  includes = [
    ./templates/macros
  ];
  name = "home-assistant-templates";
}
