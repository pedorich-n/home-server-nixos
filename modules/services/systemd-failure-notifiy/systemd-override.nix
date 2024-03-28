{ writeTextDir, unitName }:
let
  path = "/etc/systemd/system/service.d/10-on-failure-notify.conf";
  text = ''
    [Unit]
    OnFailure=${unitName}%N.service
  '';
in
writeTextDir path text
