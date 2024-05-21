{ config, lib, pkgs }:
pkgs.stdenvNoCC.mkDerivation {
  name = "authentik-blueprints";

  src = ./blueprints;

  passAsFile = [ "varsData" ];
  varsData = builtins.toJSON rec {
    inherit (config.custom.networking) domain;
    iconsProvider = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png";

    accessTokenValidity = "days=30";
    refreshTokenValidity = "days=180";

    groups = {
      serverManagement = "group: Server Management";
      homeAutomation = "group: Home Automation";
      services = "group: Services";
    };

    defaultProxyAttrs = ''
      authentication_flow: !Find [authentik_flows.flow, [slug, default-authentication-flow]]
      authorization_flow: !Find [authentik_flows.flow, [slug, default-provider-authorization-implicit-consent]]
      mode: forward_single
      access_token_validity: ${accessTokenValidity}
      refresh_token_validity: ${refreshTokenValidity}
    '';

    defaultOauthAttrs = ''
      authentication_flow: !Find [authentik_flows.flow, [slug, default-authentication-flow]]
      authorization_flow: !Find [authentik_flows.flow, [slug, default-provider-authorization-explicit-consent]]
      property_mappings:
        - !Find [authentik_providers_oauth2.scopemapping, [scope_name, openid]]
        - !Find [authentik_providers_oauth2.scopemapping, [scope_name, email]]
        - !Find [authentik_providers_oauth2.scopemapping, [scope_name, profile]]
      client_type: confidential
      access_token_validity: ${accessTokenValidity}
      refresh_token_validity: ${refreshTokenValidity}
      signing_key: !Find [authentik_crypto.certificatekeypair, [name, authentik Self-signed Certificate]]
    '';

    serverAdminsPolicy = ''
      - model: "authentik_policies.policybinding"
        identifiers:
          target: !KeyOf application
        attrs:
          group: !Find [authentik_core.group, [name, Server Admins]]
          enabled: true
          order: 0
    '';
  };

  nativeBuildInputs = with pkgs; [ jinja2-cli coreutils ];

  buildPhase = ''
    mkdir $out

    for template in ./*.yaml; do
      ${lib.getExe pkgs.jinja2-cli} --format=json "''${template}" "''${varsDataPath}" --outfile $out/$(basename ''${template})
    done
  '';
}
