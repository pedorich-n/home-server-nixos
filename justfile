import "dev/justfile.default"

deploy-remote *args:
    nix run "{{ justfile_directory() + '#deploy-remote' }}" -- {{args}}
