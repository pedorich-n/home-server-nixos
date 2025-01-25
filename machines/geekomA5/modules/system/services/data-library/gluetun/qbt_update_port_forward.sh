#!/bin/sh

QBT_HOST=${QBT_HOST:-"localhost:8080"}
PORT=$(echo "${1}" | cut -d',' -f1)
PREFIX="[qbt_update_port_forward]"
echo "${PREFIX} Updating qBittorrent's listening port to ${PORT}, ${QBT_HOST} as host"

MAX_RETRIES=5
RETRY_COUNT=0

until wget --spider --quiet "http://${QBT_HOST}/api/v2/app/version"; do
  if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
    echo "${PREFIX} Maximum retries reached. Exiting."
    exit 1
  fi

  echo "${PREFIX} Waiting for qBittorrent API to become available... (Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)"
  RETRY_COUNT=$((RETRY_COUNT + 1))
  sleep 5
done

echo "${PREFIX} qBittorrent API is available. Proceeding to update preferences."

wget --method=POST \
  --body-data="json={\"listen_port\": \"${PORT}\"}" \
  --quiet \
  "http://${QBT_HOST}/api/v2/app/setPreferences"

echo "${PREFIX} qBittorrent's listening port updated"
