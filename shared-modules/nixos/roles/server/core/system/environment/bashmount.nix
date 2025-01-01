{ pkgs, ... }: {
  environment = {
    systemPackages = [ pkgs.bashmount ];

    shellAliases.bm = "bashmount";

    etc."bashmount.conf".text = ''
      show_internal=0
    '';
  };
}
