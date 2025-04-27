{ config, ... }:
{
  security.pki.certificateFiles = [
    config.custom.certificates."step-ca/root-ca.crt"
  ];
}
