#!/bin/bash
set -euo pipefail

CONFIG_FILE="/etc/hihy/conf/config.yaml"
DATA_DIR="/root/hyll-data"

mkdir -p "$DATA_DIR"

SECRET="$(yq eval '.trafficStats.secret' "$CONFIG_FILE" 2>/dev/null | sed '/^null$/d')"
LISTEN="$(yq eval '.trafficStats.listen' "$CONFIG_FILE" 2>/dev/null | sed '/^null$/d')"
BASE="http://${LISTEN}"

[ -n "$SECRET" ] || {
  echo "未找到 trafficStats.secret 配置"
  exit 1
}

[ -n "$LISTEN" ] || {
  echo "未找到 trafficStats.listen 配置"
  exit 1
}

MONTH="$(date +%Y-%m)"
RAW_FILE="$DATA_DIR/last_raw.json"
MONTH_FILE="$DATA_DIR/${MONTH}.json"
TMP_FILE="$DATA_DIR/current_raw.json.tmp"

curl -fsS -H "Authorization: $SECRET" "$BASE/traffic" > "$TMP_FILE"

if [ ! -s "$TMP_FILE" ]; then
  echo "获取流量数据失败"
  exit 1
fi

if ! jq empty "$TMP_FILE" >/dev/null 2>&1; then
  echo "接口返回的流量数据不是合法 JSON"
  rm -f "$TMP_FILE"
  exit 1
fi

[ -f "$RAW_FILE" ] || echo '{}' > "$RAW_FILE"
[ -f "$MONTH_FILE" ] || echo '{}' > "$MONTH_FILE"

if ! jq empty "$RAW_FILE" >/dev/null 2>&1; then
  echo '{}' > "$RAW_FILE"
fi

if ! jq empty "$MONTH_FILE" >/dev/null 2>&1; then
  echo '{}' > "$MONTH_FILE"
fi

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
