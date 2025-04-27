{ inputs, lib, ... }:
let
  certificatesRoot = "${inputs.home-server-nixos-secrets}/certificates/injected";

  certificatesAttrs =
    let
      mkRelativePath = path: (lib.removePrefix "${certificatesRoot}/" (builtins.unsafeDiscardStringContext path));

      allCertificates = lib.filter (path: lib.hasSuffix ".crt" path) (lib.filesystem.listFilesRecursive certificatesRoot);

      mkCertificateEntry = path: {
        ${mkRelativePath path} = path;
      };
    in
    lib.foldl' (acc: path: acc // mkCertificateEntry path) { } allCertificates;
in
{
  options = {
    custom.certificates = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
    };
  };

  config = {
    custom.certificates = certificatesAttrs;
  };
}
