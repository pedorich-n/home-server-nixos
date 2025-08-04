{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "github-app-installation-token";
  runtimeInputs = [
    pkgs.curl
    pkgs.jq
    pkgs.openssl
  ];

  text = builtins.readFile ./app_token.sh;
}
