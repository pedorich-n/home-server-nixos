{ lib, config, ... }:
{
  ###### interface
  options = with lib; {
    custom.networking.domain = mkOption {
      type = types.str;
      default = config.networking.hostName;
    };
  };
}
