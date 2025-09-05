{
  lldapHttpPort,
  lldapAdminPasswordFile,

  pkgs,
}:
pkgs.writeShellApplication {
  name = "lldap-bootstrap-users-groups";

  runtimeInputs = [
    pkgs.lldap-bootstrap
  ];

  text = ''
    export LLDAP_URL="http://127.0.0.1:${lldapHttpPort}"
    export LLDAP_ADMIN_USERNAME="admin"
    export LLDAP_ADMIN_PASSWORD_FILE="${lldapAdminPasswordFile}"
    export USER_CONFIGS_DIR="/var/lib/lldap/bootstrap/users"
    export GROUP_CONFIGS_DIR="/var/lib/lldap/bootstrap/groups"

    export USER_SCHEMAS_DIR="/dev/null"
    export GROUP_SCHEMAS_DIR="/dev/null"
    export DO_CLEANUP="false"

    lldap-bootstrap
  '';
}
