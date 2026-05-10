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
BASELINE_FILE="$DATA_DIR/${MONTH}.baseline.json"
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

if [ ! -f "$BASELINE_FILE" ] || ! jq empty "$BASELINE_FILE" >/dev/null 2>&1; then
  mv "$TMP_FILE" "$BASELINE_FILE"
  echo "已建立本月基线：$BASELINE_FILE"
else
  rm -f "$TMP_FILE"
fi
