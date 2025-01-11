#!/bin/sh

QBT_HOST=${QBT_HOST:-"localhost:8080"}
PORT=$(echo "${1}" | cut -d',' -f1)
PREFIX="[qbt_update_port_forward]"
echo "${PREFIX} Updating qBittorrent's listening port to ${PORT}, ${QBT_HOST} as host"

until wget --spider --quiet "http://${QBT_HOST}/api/v2/app/version"; do
  echo "${PREFIX} Waiting for qBittorrent API to become available..."
  sleep 5
done

echo "${PREFIX} qBittorrent API is available. Proceeding to update preferences."

wget --method=POST \
  --body-data="json={\"listen_port\": \"${PORT}\"}" \
  --quiet \
  "http://${QBT_HOST}/api/v2/app/setPreferences"

echo "${PREFIX} qBittorrent's listening port updated"
