{ inputs, config, pkgs, ... }:
let
  rendererLib = inputs.jinja2-renderer.lib.${pkgs.system};
in
{
  _module.args.jinja2RendererLib = rendererLib // {
    render-templates-with-global-macros = { includes ? [ ], variables ? { }, ... } @ args:
      let
        extraArgs = builtins.removeAttrs args [ "includes" "variables" ];
      in
      rendererLib.render-templates (extraArgs // {
        includes = includes ++ [ ./jinja2-macros/global_utils.j2 ];
        variables = variables // {
          server_domain = config.custom.networking.domain;
          icons_base_url = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png";
        };
      });
  };
}
