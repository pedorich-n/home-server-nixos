{ lib, ... }:
{
  provider.b2 = {
    application_key_id = lib.tfRef "local.secrets.backblaze_terranix.API.application_key_id";
    application_key = lib.tfRef "local.secrets.backblaze_terranix.API.application_key";
  };
}
