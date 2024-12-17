{
  terraform = {
    required_version = ">= 1.8";
    backend."local" = { };

    required_providers = {
      netparse = {
        source = "gmeligio/netparse";
        version = "0.0.3";
      };

      # Configured using ENV variables, see https://registry.terraform.io/providers/Backblaze/b2/0.9.0/docs#optional
      b2 = {
        source = "Backblaze/b2";
        version = "~> 0.9";
      };

      # Configured using ENV variables, see https://registry.terraform.io/providers/1Password/onepassword/2.1.2/docs#authenticate-cli-with-service-accountc
      onepassword = {
        source = "1Password/onepassword";
        version = "~> 2.1";
      };
    };
  };
}
