{ pkgs, ... }:
let
  configRaw = ''
    listener 1883
    allow_anonymous false
    password_file /mosquitto/config/passwords.txt
  '';
in
pkgs.writeText "mosquitto.conf" configRaw
