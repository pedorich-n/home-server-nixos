{
  config,
  networkingLib,
  autheliaLib,
  ...
}:
let
  baseDN = config.services.lldap.settings.ldap_base_dn;
in
{
  sops.templates = {
    "media-library/jellyfin/ldap-auth.xml" = {
      owner = config.services.jellyfin.user;
      group = config.services.jellyfin.group;
      restartUnits = [
        config.systemd.services.jellyfin.name
      ];
      # See https://github.com/lldap/lldap#general-configuration-guide
      # See https://github.com/lldap/lldap/blob/3bf9ea5206fb2fb4ff356d2cf13d4543c425b8e6/example_configs/jellyfin.md
      content = ''
        <?xml version="1.0" encoding="utf-8"?>
        <PluginConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
          <LdapUsers />
          <LdapServer>${networkingLib.mkDomain "lldap"}</LdapServer>
          <LdapPort>${config.custom.networking.ports.tcp.lldap-ldaps.portStr}</LdapPort>
          <UseSsl>true</UseSsl>
          <UseStartTls>false</UseStartTls>
          <SkipSslVerify>false</SkipSslVerify>
          <LdapBindUser>UID=${config.sops.placeholder."lldap/users/jellyfin/username"},OU=people,${baseDN}</LdapBindUser>
          <LdapBindPassword>${config.sops.placeholder."lldap/users/jellyfin/password"}</LdapBindPassword>
          <LdapBaseDn>OU=people,${baseDN}</LdapBaseDn>
          <LdapSearchFilter>(uid=*)</LdapSearchFilter>
          <LdapAdminBaseDn>OU=people,${baseDN}</LdapAdminBaseDn>
          <LdapAdminFilter>(memberOf=CN=${autheliaLib.groups.Admins},OU=groups,${baseDN})</LdapAdminFilter>
          <EnableLdapAdminFilterMemberUid>false</EnableLdapAdminFilterMemberUid>
          <LdapSearchAttributes>uid, cn, mail, displayName</LdapSearchAttributes>
          <CreateUsersFromLdap>true</CreateUsersFromLdap>
          <AllowPassChange>false</AllowPassChange>
          <LdapUidAttribute>uid</LdapUidAttribute>
          <LdapUsernameAttribute>uid</LdapUsernameAttribute>
          <LdapProfileImageAttribute>jpegphoto</LdapProfileImageAttribute>
          <EnableAllFolders>true</EnableAllFolders>
          <EnabledFolders />
        </PluginConfiguration>
      '';
    };
  };

}
