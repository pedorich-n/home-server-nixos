{
  config,
  networkingLib,
  ...
}:
{
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "pedorich.n@gmail.com";
      dnsResolver = "1.1.1.1:53";
    };

    certs = {
      local = {
        domain = config.custom.networking.domain;
        extraDomainNames = [
          (networkingLib.mkDomain "*")
        ];
        dnsProvider = "cloudflare";

        # See https://go-acme.github.io/lego/dns/cloudflare/index.html
        credentialFiles = {
          "CF_DNS_API_TOKEN_FILE" = config.sops.secrets."cloudflare/api_tokens/acme".path;
        };

        reloadServices = [
          config.systemd.services.traefik.name
          config.systemd.services.caddy.name
        ];
      };
    };
  };
}
