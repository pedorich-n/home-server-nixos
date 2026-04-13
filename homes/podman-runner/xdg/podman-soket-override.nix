{
  xdg.configFile."systemd/user/podman.socket.d/override.conf".text = ''
    [Socket]
    SocketMode=0666
  '';
}
