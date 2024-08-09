import argparse
import json
from pathlib import Path
from typing import Dict, List, Optional

from jinja2 import Environment, FileSystemLoader, StrictUndefined, Template


def maybe_load_variables(json_file: Optional[Path]) -> dict:
    """Load variables from a JSON file."""
    if json_file:
        with open(json_file, "r") as f:
            return json.load(f)
    else:
        return {}


def render_template(template: Template, variables: Dict, output: Path) -> None:
    """Render a Jinja2 template and save it to a file."""
    rendered_content = template.render(variables)
    with open(output, "w") as output_file:
        output_file.write(rendered_content)
    print(f"Rendered and saved to {output}")


def render_templates(templates_root: Path, includes: List[Path], output_root: Path, variables_path: Optional[Path], strict: bool) -> None:
    paths = [templates_root]
    paths.extend(includes)
    env = Environment(
        loader=FileSystemLoader(paths),
        trim_blocks=True,
        lstrip_blocks=True,
    )
    if strict:
        env.undefined = StrictUndefined

    variables = maybe_load_variables(variables_path)
    output_root.mkdir(exist_ok=True)

    # Iterate through all template files in the template folder
    for template_path in templates_root.glob("*.j2"):
        print(f"Loading {template_path}")
        template = env.get_template(template_path.name)

        # Strip the .j2 extension and save to the rendered folder
        output_filename = template_path.stem
        output_path = output_root.joinpath(output_filename)

        render_template(template, variables, output_path)


def main():
    parser = argparse.ArgumentParser(formatter_class=lambda prog: argparse.ArgumentDefaultsHelpFormatter(prog, max_help_position=60))
    parser.add_argument("--templates", type=Path, required=True, help="Path to templates to render")
    parser.add_argument("--include", type=Path, required=False, nargs="+", help="Extra folder(s) to include", default=[])
    parser.add_argument("--output", type=Path, required=True, help="Path to output folder")
    parser.add_argument("--variables", type=Path, required=False, help="Path to JSON variables to use for substitution")
    parser.add_argument("--strict", action="store_true", required=False, help="If set, no undefined variables are allowed", default=False)

    args = parser.parse_args()

    render_templates(
        templates_root=args.templates, includes=args.include, output_root=args.output, variables_path=args.variables, strict=args.strict
    )
