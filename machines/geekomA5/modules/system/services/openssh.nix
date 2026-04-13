{
  config,
  ...
}:
{
  services.openssh = {
    settings.DenyUsers = [
      config.users.users.podman-runner.name
    ];
  };
}
