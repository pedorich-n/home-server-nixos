{ pkgs, inputs, ... }: {
  _module.args.jinja2RendererLib = inputs.jinja2-renderer.lib.${pkgs.system};
}
