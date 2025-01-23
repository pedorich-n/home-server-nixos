{
  custom.onepassword = {
    enable = true;

    vaults = {
      homelab.name = "HomeLab";
    };

    items = {
      tailscale = {
        vault = "homelab";
        title = "Tailscale";
      };
    };
  };
}
