{ config, ... }: {
  custom.networking.ports.tcp.step-ca = { port = 18443; openFirewall = true; };

  services.step-ca = {
    inherit (config.custom.networking.ports.tcp.step-ca) port openFirewall;
    enable = true;
    address = "0.0.0.0";

    intermediatePasswordFile = config.sops.secrets."step-ca/intermediate/password".path;

    settings = {
      crt = config.sops.secrets."step-ca/intermediate/certificate".path;
      key = config.sops.secrets."step-ca/intermediate/key".path;
      root = config.sops.secrets."step-ca/root/certificate".path;
      dnsNames = [
        "ca.${config.custom.networking.domain}"
      ];
      logger = { format = "text"; };
      authority = {
        backdate = "1m0s";
        provisioners = [
          {
            claims = {
              defaultTLSCertDuration = "4320h"; # 180 days
              maxTLSCertDuration = "5040h"; # 210 days
            };
            name = "acme";
            type = "ACME";
          }
        ];
      };
      db = {
        dataSource = "/var/lib/step-ca/db";
        type = "badgerv2";
      };
      tls = {
        cipherSuites = [
          "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256"
          "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
        ];
        maxVersion = 1.3;
        minVersion = 1.2;
        renegotiation = false;
      };
    };

  };
}
