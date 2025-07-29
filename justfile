import "dev/justfile.default"

_deploy hostname *args:
    just _run "deploy" {{ hostname }} {{ args }}

_dry_deploy hostname *args:
    just _deploy "{{ hostname }}" "--dry-activate {{ args }}"

build-geekomA5 *args:
    just _build nixosConfigurations.geekomA5.config.system.build.toplevel {{ args }}

deploy-geekomA5 *args:
    just _deploy geekomA5 "{{ args }}"

dry-deploy-geekomA5 *args:
    just _dry_deploy geekomA5 "{{ args }}"

build-iso *args:
    just _run  "build-iso" "minimal"

generate-host-keys:
    just _run generate-host-keys

convert-host-keys root:
    just _run convert-host-keys {{ root }}

shell-tf:
    just _develop tf

shell-updater:
    just _develop version-updater
