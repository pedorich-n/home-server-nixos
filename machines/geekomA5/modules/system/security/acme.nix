{
  config,
  networkingLib,
  lib,
  ...
}:
{
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = config.custom.secrets.plaintext.variables.email;
      dnsResolver = "1.1.1.1:53";
    };

    certs = {
      local = {
        domain = config.custom.networking.domain;
        extraDomainNames = [
          (networkingLib.mkDomain "*")
        ];
        dnsProvider = "cloudflare";

        # It gets overwritten to "caddy" by https://github.com/NixOS/nixpkgs/blob/b77b3de8775677f84492abe84635f87b0e153f0f/nixos/modules/services/web-servers/caddy/default.nix#L475
        group = lib.mkForce config.security.acme.defaults.group;

        # See https://go-acme.github.io/lego/dns/cloudflare/index.html
        credentialFiles = {
          "CF_DNS_API_TOKEN_FILE" = config.sops.secrets."cloudflare/api_tokens/acme".path;
        };

        reloadServices = [
          config.systemd.services.caddy.name
        ];
      };
    };
  };
}
