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

  mkRouteMatcher = route: if route.matcher != null then route.matcher else route.path;

  mkRouteUpstream = route: host: if route.upstream != null then route.upstream else host.upstream;

  mkRouteAuth = route: host: if route.auth == "inherit" then host.auth else route.auth;

  mkRouteHandle =
    route: host:
    let
      auth = mkRouteAuth route host;
    in
    ''
      handle ${mkRouteMatcher route} {
        ${lib.optionalString (auth != null) "import forward-auth-${auth}"}
        reverse_proxy ${mkRouteUpstream route host}
      }
    '';

  mkProxyBody =
    host:
    let
      auth = host.auth;
      lines = lib.optional (auth != null) "import forward-auth-${auth}" ++ [ "reverse_proxy ${host.upstream}" ];
      body = lib.concatStringsSep "\n" lines;
    in
    if host.routes == [ ] then
      body
    else
      ''
        handle {
          ${body}
        }
      '';

  mkStaticBody = host: ''
    root * ${host.root}
    file_server
  '';

  mkRedirectBody = host: ''
    redir ${host.target}{uri} permanent
  '';

  mkHostBody =
    host:
    let
      main =
        if host.kind == "static" then
          mkStaticBody host
        else if host.kind == "redirect" then
          mkRedirectBody host
        else
          lib.concatStringsSep "\n" (lib.map (route: mkRouteHandle route host) host.routes ++ [ (mkProxyBody host) ]);
    in
    lib.concatLines [
      main
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
              default = networkingLib.mkLocalDomain name;
              description = "Hostname for the virtual host. Defaults to <name>.<domain>.";
            };

            kind = lib.mkOption {
              type = lib.types.enum [
                "proxy"
                "static"
                "redirect"
              ];
              default = "proxy";
              description = ''
                - proxy: reverse_proxy to upstream (default)
                - static: file_server on root
                - redirect: redir <target>{uri} permanent
              '';
            };

            upstream = lib.mkOption {
              type = lib.types.nullOr lib.types.nonEmptyStr;
              default = null;
              description = ''
                Caddy upstream address, e.g. http://127.0.0.1:8080 or unix//run/app/app.sock.
                Required when kind = "proxy".
              '';
            };

            root = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = "Filesystem path to serve when kind = \"static\".";
            };

            target = lib.mkOption {
              type = lib.types.nullOr lib.types.nonEmptyStr;
              default = null;
              description = ''
                Redirection target URL (without trailing slash and without {uri})
                when kind = "redirect".
              '';
            };

            auth = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "authelia"
                  "authelia-basic"
                ]
              );
              default = null;
              description = ''
                Default forward auth variant for the catch-all:
                - "authelia": cookie session SSO, for browser-facing UIs
                - "authelia-basic": also accepts HTTP Basic Auth, for WebDAV/API clients
                - null: no auth
                Can be overridden per route.
              '';
            };

            routes = lib.mkOption {
              type = lib.types.listOf (
                lib.types.submodule {
                  options = {
                    path = lib.mkOption {
                      type = lib.types.nullOr lib.types.nonEmptyStr;
                      default = null;
                      description = ''
                        Shorthand for `matcher = "path <value>"`.
                        Ignored if `matcher` is also set.
                      '';
                    };
                    matcher = lib.mkOption {
                      type = lib.types.nullOr lib.types.lines;
                      default = null;
                      description = ''
                        Raw Caddy matcher expression, e.g. 'not path /share/* /rest/*'.
                        Takes precedence over `path` if both are set.
                      '';
                    };
                    upstream = lib.mkOption {
                      type = lib.types.nullOr lib.types.nonEmptyStr;
                      default = null;
                      description = "Override host upstream for this route.";
                    };
                    auth = lib.mkOption {
                      type = lib.types.nullOr (
                        lib.types.enum [
                          "inherit"
                          "authelia"
                          "authelia-basic"
                        ]
                      );
                      default = "inherit";
                      description = ''
                        Auth strategy for this route:
                        - "inherit" (default): use the host's auth setting
                        - "authelia": cookie SSO
                        - "authelia-basic": also accepts HTTP Basic Auth
                        - null: no auth on this route
                      '';
                    };
                  };
                }
              );
              default = [ ];
              description = "Ordered routes evaluated before the catch-all. First match wins.";
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
    assertions = lib.flatten (
      lib.mapAttrsToList (
        hostName: host:
        lib.imap1 (idx: route: {
          assertion = (route.path == null) != (route.matcher == null);
          message = "custom.services.caddy.hosts.${hostName}.routes[${toString idx}]: exactly one of `path` or `matcher` must be set.";
        }) host.routes
      ) cfg
    );

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
          extraConfig = mkHostBody value;
        };
      }) cfg;
    };
  };
}
