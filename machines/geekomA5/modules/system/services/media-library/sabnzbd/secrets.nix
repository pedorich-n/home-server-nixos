{
  config,
  ...
}:
{
  sops.templates = {
    "media-library/sabnzbd/secrets.ini" = {
      owner = config.services.sabnzbd.user;
      group = config.services.sabnzbd.group;
      restartUnits = [
        config.systemd.services.sabnzbd.name
      ];
      content = ''
        [misc]
        api_key = ${config.sops.placeholder."sabnzbd/api_key"}
        nzb_key = ${config.sops.placeholder."sabnzbd/nzb_key"}
        [servers]
        [[blocknews]]
        username = ${config.sops.placeholder."sabnzbd/servers/blocknews/username"}
        password = ${config.sops.placeholder."sabnzbd/servers/blocknews/password"}
        [[thundernews]]
        username = ${config.sops.placeholder."sabnzbd/servers/thundernews/username"}
        password = ${config.sops.placeholder."sabnzbd/servers/thundernews/password"}
      '';
    };
  };

}
