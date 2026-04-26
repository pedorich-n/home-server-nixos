{
  writeShellApplication,
  curl,
  jq,
  openssl,
  ...
}:
writeShellApplication {
  name = "github-app-installation-token";
  runtimeInputs = [
    curl
    jq
    openssl
  ];

  text = builtins.readFile ./app_token.sh;
}
