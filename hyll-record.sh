#!/bin/bash
set -euo pipefail

CONFIG_FILE="/etc/hihy/conf/config.yaml"
DATA_DIR="/root/hyll-data"

mkdir -p "$DATA_DIR"

SECRET="$(yq eval '.trafficStats.secret' "$CONFIG_FILE")"
LISTEN="$(yq eval '.trafficStats.listen' "$CONFIG_FILE")"
BASE="http://${LISTEN}"

MONTH="$(date +%Y-%m)"
RAW_FILE="$DATA_DIR/last_raw.json"
MONTH_FILE="$DATA_DIR/${MONTH}.json"
TMP_FILE="$DATA_DIR/current_raw.json.tmp"

curl -s -H "Authorization: $SECRET" "$BASE/traffic" > "$TMP_FILE"

if [ ! -s "$TMP_FILE" ]; then
  echo "failed to fetch traffic"
  exit 1
fi

[ -f "$RAW_FILE" ] || echo '{}' > "$RAW_FILE"
[ -f "$MONTH_FILE" ] || echo '{}' > "$MONTH_FILE"

jq -n \
  --slurpfile oldraw "$RAW_FILE" \
  --slurpfile newraw "$TMP_FILE" \
  --slurpfile monthsum "$MONTH_FILE" '
  def users:
    (($oldraw[0] // {}) + ($newraw[0] // {}) + ($monthsum[0] // {})) | keys[];

  reduce users as $u
    ({};
      .[$u] = {
        tx: (
          (($monthsum[0][$u].tx // 0)) +
          (
            if (($newraw[0][$u].tx // 0) >= ($oldraw[0][$u].tx // 0))
            then (($newraw[0][$u].tx // 0) - ($oldraw[0][$u].tx // 0))
            else ($newraw[0][$u].tx // 0)
            end
          )
        ),
        rx: (
          (($monthsum[0][$u].rx // 0)) +
          (
            if (($newraw[0][$u].rx // 0) >= ($oldraw[0][$u].rx // 0))
            then (($newraw[0][$u].rx // 0) - ($oldraw[0][$u].rx // 0))
            else ($newraw[0][$u].rx // 0)
            end
          )
        )
      }
    )
' > "${MONTH_FILE}.tmp"

mv "${MONTH_FILE}.tmp" "$MONTH_FILE"
mv "$TMP_FILE" "$RAW_FILE"
