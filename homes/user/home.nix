{ inputs, ... }: {
  imports = [
    inputs.home-manager-config.homeModules.common
  ];
}
