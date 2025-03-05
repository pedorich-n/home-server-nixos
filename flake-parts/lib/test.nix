{ inputs, ... }: {
  flake.lib.test = {
    modpack = inputs.nix-minecraft.legacyPackages.x86_64-linux.fetchPackwizModpack {
      url = "https://gitlab.com/pablo_peraza/moneyguys-explorationrevival/-/raw/master/pack.toml";
      pname = "money-guys-exploration";
      version = "0.5.2";
    };
  };
}
