{
  virtualisation.arion = {
    backend = "podman-socket";
  };

  # TODO: remove after https://github.com/NixOS/nixpkgs/pull/305803 is merged
  systemd.sockets.podman.socketConfig.ListenStream = [
    "/run/podman/podman.sock"
    "/run/docker.sock"
  ];
}
