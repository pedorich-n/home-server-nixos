_:
let

  # Same as config.sops.secrets."step-ca/root/certificate".path, 
  #  but `security.pki.certificates*` requires certificate to be preset at build time
  certificate = ''
    HomeLab Root CA
    -----BEGIN CERTIFICATE-----
    MIIBmjCCAUGgAwIBAgIQHpiOVDsjUEY+L0Kxnz1NRDAKBggqhkjOPQQDAjAsMRAw
    DgYDVQQKEwdIb21lTGFiMRgwFgYDVQQDEw9Ib21lTGFiIFJvb3QgQ0EwHhcNMjUw
    NDI2MDgyMjU3WhcNMzUwNDI0MDgyMjU3WjAsMRAwDgYDVQQKEwdIb21lTGFiMRgw
    FgYDVQQDEw9Ib21lTGFiIFJvb3QgQ0EwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNC
    AASC8i7WtrAkNouQjPDhrCUIBv2nuVWP0SntzrcsVYPUu5U8CBjv80q9/jEJaHEI
    PcjcFr/p2ndlXROyViGjnN3io0UwQzAOBgNVHQ8BAf8EBAMCAQYwEgYDVR0TAQH/
    BAgwBgEB/wIBATAdBgNVHQ4EFgQU/fUGaPSuZg5/p+y2P3lap8Y/+RkwCgYIKoZI
    zj0EAwIDRwAwRAIgAPAZKNMpLkYAivsweVKQ/JJ9ac5732lTMsZGIYie7ywCIBxo
    c6b4BYQcyb75EgK7NJ9hdF8rrN8AkeG4lkYAiE2B
    -----END CERTIFICATE-----
  '';
in
{
  security.pki.certificates = [ certificate ];
  # security.pki.certificateFiles = (lib.mkIf (config.sops.secrets ? "step-ca/root/certificate") [
  #   config.sops.secrets."step-ca/root/certificate".path
  # ]);
}
