import "dev/justfile.default"

deploy-remote:
    nix run "{{ justfile_directory() + '#deploy-remote' }}"
