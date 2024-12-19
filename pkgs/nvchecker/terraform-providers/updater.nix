{ pkgs, lib, ... }:
let
  config = import ./config.nix { inherit pkgs lib; };
in
pkgs.writeShellApplication {
  name = "update-terraform-providers";
  runtimeInputs = [
    pkgs.gitMinimal
    pkgs.jq
    (pkgs.python3.withPackages (ps: with ps; [
      nvchecker
      jq
    ]))
  ];

  passthru = {
    inherit config;
  };

  text = ''
    TARGET=$(mktemp --directory -t terraform_providers_update.XXXXXXXXXX)
    export TARGET

    function cleanup {
      rm -r "''${TARGET}"
    }
    trap cleanup EXIT

    nvchecker --file ${config.nvcheckerToml}

    VERSIONS="''${TARGET}/versions.json"
    jq '.data' "''${TARGET}/output.json" > "''${VERSIONS}"

    ROOT="$(git rev-parse --show-toplevel)"
    RESULT="''${ROOT}/versions/terraform-providers.json"

    jq --slurp 'reduce .[] as $item ({}; . * $item)' "${config.providersJson}" "''${VERSIONS}" > "''${RESULT}"
    echo "Stored result in ''${RESULT}"
  '';
}
