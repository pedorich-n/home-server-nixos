{
  terraform = {
    required_version = ">= 1.5";
    backend."local" = { };

    required_providers = {
      tailscale = {
        source = "tailscale/tailscale";
        version = "~> 0.17";
      };
    };
  };
}
