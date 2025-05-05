import "dev/justfile.default"

extra_dev_config := justfile_directory() / 'dev-extra-config.nix'

_build target *args:
    nix build "{{ justfile_directory() + '#' + target }}" {{ if args != "" { '-- ' + args } else { '' } }} 

_deploy hostname *args:
    nix run "{{ justfile_directory() + '#deploy' }}" -- {{ hostname }} {{ args }}

_dry_deploy hostname *args:
    just _deploy "{{ hostname }}" --dry-activate {{ args }}

build-geekomA5 *args:
    just _build nixosConfigurations.geekomA5.config.system.build.toplevel {{ args }}

deploy-geekomA5 *args:
    just _deploy geekomA5 "{{ args }}"

dry-deploy-geekomA5 *args:
    just _dry_deploy geekomA5 "{{ args }}"

build-iso *args:
    nix run "{{ justfile_directory() + '#build-iso' }}" -- "minimal"

check:
    nix flake check "{{ justfile_directory() }}"

generate-host-keys:
    nix run "{{ justfile_directory() + '#generate-host-keys' }}"
