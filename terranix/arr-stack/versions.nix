{
  terraform = {
    required_version = ">= 1.5";
    backend."local" = { };

    required_providers = {
      prowlarr = {
        source = "devopsarr/prowlarr";
        version = "~> 2.4";
      };
    };
  };
}
