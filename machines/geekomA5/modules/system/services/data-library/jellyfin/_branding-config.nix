{ pkgs, networkingLib, ... }:
let
  xmlFormat = pkgs.formats.xml { };
in
# See https://github.com/9p4/jellyfin-plugin-sso
xmlFormat.generate "branding.xml" {
  BrandingOptions = {
    LoginDisclaimer = ''
      <form action="${networkingLib.mkUrl "jellyfin"}/sso/OID/start/Authelia">
        <button class="raised button-submit block emby-button">
          Sign in with Authelia
        </button>
      </form>
    '';

    CustomCss = ''
      a.raised.emby-button,
      .loginDisclaimerContainer,
      .loginDisclaimer {
          all: unset;    
      }

      .btnQuick,
      .btnSelectServer,
      .btnForgotPassword,
      a.raised.emby-button,
      .emby-button.block,
      .manualLoginForm,
      .loginDisclaimerContainer,
      .loginDisclaimer {
          margin-left: auto;
          margin-right: auto;
          margin-bottom: 1em;
          color: inherit !important;
      }
    '';

    SplashscreenEnabled = false;
  };
}
