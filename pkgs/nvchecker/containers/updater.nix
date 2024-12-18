{ pkgs, lib, ... }:
let
  config = import ./config.nix { inherit pkgs lib; };
in
pkgs.writeShellApplication {
  name = "update-containers";
  runtimeInputs = [
    pkgs.gitMinimal
    pkgs.nvchecker
    pkgs.jq
  ];

  passthru = {
    inherit config;
  };

  text = ''
    TARGET=$(mktemp --directory -t containers_update.XXXXXXXXXX)
    export TARGET

    function cleanup {
      rm -r "''${TARGET}"
    }
    trap cleanup EXIT

    nvchecker --file ${config.nvcheckerToml}

    VERSIONS="''${TARGET}/versions.json"
    jq '.data' "''${TARGET}/output.json" > "''${VERSIONS}"

    ROOT="$(git rev-parse --show-toplevel)"
    RESULT="''${ROOT}/containers/containers.json"

    jq --slurp 'reduce .[] as $item ({}; . * $item)' "${config.containersJson}" "''${VERSIONS}" > "''${RESULT}"
    echo "Stored result in ''${RESULT}"
  '';
}
