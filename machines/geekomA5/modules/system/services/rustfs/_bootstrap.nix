{
  writeShellApplication,
  rustfs-cli,
  adminAccessKeyFile,
  adminSecretKeyFile,
  gristAccessKeyFile,
  gristSecretKeyFile,
  bindAddress,
  bindPort,
  gristPolicy,
}:
writeShellApplication {
  name = "rustfs-bootstrap";
  runtimeInputs = [ rustfs-cli ];

  text = ''
    set -eu

    mkdir -p /var/lib/rustfs/rc
    export RC_CONFIG_DIR=/var/lib/rustfs/rc

    admin_ak=$(tr -d '\n' < ${adminAccessKeyFile})
    admin_sk=$(tr -d '\n' < ${adminSecretKeyFile})
    grist_ak=$(tr -d '\n' < ${gristAccessKeyFile})
    grist_sk=$(tr -d '\n' < ${gristSecretKeyFile})

    rc alias set rustfs_admin http://${bindAddress}:${bindPort} \
      "$admin_ak" "$admin_sk"

    for _ in $(seq 1 60); do
      if rc admin info cluster rustfs_admin > /dev/null 2>&1; then
        break
      fi
      sleep 1
    done
    if ! rc admin info cluster rustfs_admin > /dev/null 2>&1; then
      echo "rustfs admin API did not become reachable on ${bindAddress}:${bindPort}" >&2
      exit 1
    fi

    rc mb rustfs_admin/grist 2>/dev/null || true
    rc bucket version enable rustfs_admin/grist

    if ! rc admin access-key info rustfs_admin "$grist_ak" > /dev/null 2>&1; then
      rc admin service-account create rustfs_admin "$grist_ak" "$grist_sk" \
        --policy ${gristPolicy}
    fi
  '';
}
