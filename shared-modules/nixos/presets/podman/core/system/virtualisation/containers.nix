{
  virtualisation.containers.containersConf.settings = {
    network = {
      # Runs DNS server on alternate port. See https://github.com/containers/common/blob/3e255710/docs/containers.conf.5.md?plain=1#L466-L471
      dns_bind_port = 5453;
    };
  };
}
