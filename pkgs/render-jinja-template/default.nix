{ lib, runCommandNoCC, jinja2-cli }:
{ name, vars, template }:
runCommandNoCC name
{
  passAsFile = [ "varsData" ];
  varsData = builtins.toJSON vars;
  nativeBuildInputs = [ jinja2-cli ];
} ''${lib.getExe jinja2-cli} --format=json ${template} $varsDataPath --outfile $out''

