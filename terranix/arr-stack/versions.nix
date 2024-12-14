{
  terraform = {
    required_version = ">= 1.5";

    required_providers = {
      prowlarr = {
        source = "devopsarr/prowlarr";
        version = "~> 2.4";
      };
    };
  };
}
