/* inputs: final: prev: */
_: _: prev: {
  minecraft-server-check = prev.callPackage ../pkgs/minecraft-server-check { };
  systemd-onfailure-notify = prev.callPackage ../pkgs/systemd-onfailure-notify { };
}
