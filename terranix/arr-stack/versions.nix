{
  terraform = {
    required_version = ">= 1.5";
    backend."local" = { };

    required_providers = {
      prowlarr = {
        source = "devopsarr/prowlarr";
        version = "~> 2.4";
      };

      radarr = {
        source = "devopsarr/radarr";
        version = "~> 2.3";
      };

      sonarr = {
        source = "devopsarr/sonarr";
        version = "~> 3.3";
      };
    };
  };
}
