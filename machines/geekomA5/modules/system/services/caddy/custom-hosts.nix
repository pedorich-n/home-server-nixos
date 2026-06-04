{
  config,
  lib,
  networkingLib,
  ...
}:
let
  cfg = config.custom.services.caddy.hosts;

  #LINK - machines/geekomA5/modules/system/services/authelia/authelia.nix:63
  autheliaAddress = "unix//run/authelia-main/authelia.sock";
  copyHeaders = "Remote-User Remote-Groups Remote-Email Remote-Name";

  mkVirtualHostConfig =
    host:
    lib.concatLines [
      # Auth-bypass paths: routed directly to the upstream, no auth applied.
      # Must come before the main handle block since Caddy handle blocks are ordered.
      (lib.concatMapStrings (path: ''
        handle ${path} {
          reverse_proxy ${host.upstream}
        }
      '') host.authBypassPaths)

      # Main handler
      (
        if host.auth != null && host.authBypassPaths != [ ] then
          # Bypass paths exist: wrap forward_auth inside a catch-all handle block
          # so it only applies to paths not matched above.
          ''
            handle {
              import forward-auth-${host.auth}
              reverse_proxy ${host.upstream}
            }
          ''
        else if host.auth != null then
          ''
            import forward-auth-${host.auth}
            reverse_proxy ${host.upstream}
          ''
        else
          "reverse_proxy ${host.upstream}"
      )

      "import error-handler"

      host.extraConfig
    ];
in
{
  options.custom.services.caddy.hosts = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        {
          name,
          ...
        }:
        {
          options = {
            domain = lib.mkOption {
              type = lib.types.nonEmptyStr;
              default = networkingLib.mkDomain name;
              description = "Hostname for the virtual host. Defaults to <name>.<domain>.";
            };

            upstream = lib.mkOption {
              type = lib.types.nonEmptyStr;
              description = "Caddy upstream address, e.g. http://127.0.0.1:8080 or unix//run/app/app.sock";
            };

            auth = lib.mkOption {
              type = lib.types.enum [
                null
                "authelia"
                "authelia-basic"
              ];
              default = null;
              description = ''
                Forward auth variant to apply:
                - "authelia": cookie session SSO, for browser-facing UIs
                - "authelia-basic": also accepts HTTP Basic Auth, for WebDAV/API clients
                - null: no auth
              '';
            };

            authBypassPaths = lib.mkOption {
              type = lib.types.listOf lib.types.nonEmptyStr;
              default = [ ];
              description = ''
                Path prefixes that bypass auth and go directly to the upstream.
                Requires auth to be set. Example: [ "/api" ] for arr-stack API access.
              '';
            };

            useTLS = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Whether to serve this host over HTTPS using the local ACME cert.
                Set to false for plain HTTP virtual hosts (domain will be prefixed with http://).
              '';
            };

            extraConfig = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = "Raw Caddyfile directives appended to the site block.";
            };
          };
        }
      )
    );
    default = { };
    description = "HTTPS virtual hosts to expose via Caddy.";
  };

  config = lib.mkIf (cfg != { }) {
    services.caddy = {
      # mkBefore so that the snippet is included before any virtual host configs
      extraConfig = lib.mkBefore ''
        (forward-auth-authelia) {
          forward_auth ${autheliaAddress} {
            uri /api/authz/forward-auth
            copy_headers ${copyHeaders}
          }
        }

        (forward-auth-authelia-basic) {
          forward_auth ${autheliaAddress} {
            uri /api/authz/forward-auth-basic
            copy_headers ${copyHeaders}
          }
        }
      '';

      virtualHosts = lib.mapAttrs' (_name: value: {
        name = if value.useTLS then value.domain else "http://${value.domain}";
        value = {
          # Should be the same as `security.acme.certs.<name>`
          #LINK - machines/geekomA5/modules/system/security/acme.nix:15
          logFormat = null; # Disable access logs
          useACMEHost = if value.useTLS then "local" else null;
          extraConfig = mkVirtualHostConfig value;
        };
      }) cfg;
    };
  };
}
