{ writeShellApplication
, mc-monitor
, systemd
, lib
, pidPath
, serverAddress
, serverPort ? 25565
, retries ? 15
, interval ? "5s"
, serverName ? ""
, ...
}:
writeShellApplication {
  name = "server-check" + lib.optionalString (serverName != "") "-${serverName}";
  runtimeInputs = [
    mc-monitor
    systemd
  ];
  bashOptions = [ "nounset" "pipefail" ];

  text = ''
    check() {
      mc-monitor -debug status \
                 -retry-limit ${builtins.toString retries} \
                 -retry-interval ${interval} \
                 -host ${serverAddress} \
                 -port ${builtins.toString serverPort}
    }

    if check; then
      pid=$(cat ${pidPath})
      echo "Main PID is: $pid"
      systemd-notify --pid="$pid" --ready --status="Up and running..."
    fi
  '';
}
