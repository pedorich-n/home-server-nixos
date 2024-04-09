import "dev/justfile.default"

_deploy hostname *args:
    nix run "{{ justfile_directory() + '#deploy-' + hostname }}" {{ if args != "" { '-- ' + args } else { '' } }} 

_dry_deploy hostname *args:
    just _deploy "{{ hostname }}" "--dry-activate {{ args }}"

deploy-nucbox5 *args:
    just _deploy nucbox5 "{{ args }}"

dry-deploy-nucbox5 *args:
    just _dry_deploy nucbox5 "{{ args }}"

build-iso *args:
    nix run "{{ justfile_directory() + '#build-iso-minimal' }}"

check:
    nix flake check "{{ justfile_directory() }}"
