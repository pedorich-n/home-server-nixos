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

        environmentFile = config.sops.secrets."acme/cloudflare.env".path;
      };
    };
  };
}
