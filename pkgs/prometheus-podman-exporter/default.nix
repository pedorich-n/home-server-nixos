{ pkgs, ... }:
let
  sources = (pkgs.callPackage ./_sources/generated.nix { }).prometheus-podman-exporter;
in
pkgs.buildGoModule {
  inherit (sources) pname version src;

  nativeBuildInputs = with pkgs; [
    pkg-config
  ];

  buildInputs = with pkgs; [
    btrfs-progs
    gpgme
    libassuan
    lvm2
  ];

  vendorHash = null;
  doCheck = false;

  meta.mainProgram = "prometheus-podman-exporter";
}
