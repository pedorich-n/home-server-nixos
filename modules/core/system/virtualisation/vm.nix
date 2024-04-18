{ lib, ... }: {
  virtualisation = {
    vmVariant = {
      virtualisation = {
        cores = lib.mkDefault 8;
        memorySize = lib.mkDefault 4096;
        diskSize = lib.mkDefault 7224;
      };
    };

  };
}
