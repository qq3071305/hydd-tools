#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="/etc/hihy/conf/config.yaml"
DATA_DIR="/root/hyll-data"

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root"
    exit 1
  fi
}

need_hihy() {
  [ -f "$CONFIG_FILE" ] || {
    echo "Hi_Hysteria config not found: $CONFIG_FILE"
    echo "Install Hi_Hysteria first, then run this installer."
    exit 1
  }
}

detect_pm() {
  if command -v apt >/dev/null 2>&1; then
    echo "apt"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v yum >/dev/null 2>&1; then
    echo "yum"
  elif command -v apk >/dev/null 2>&1; then
    echo "apk"
  else
    echo "unknown"
  fi
}

install_deps() {
  local pm
  pm="$(detect_pm)"
  case "$pm" in
    apt)
      apt update
      apt install -y curl jq qrencode cron
      ;;
    dnf)
      dnf install -y curl jq qrencode cronie
      ;;
    yum)
      yum install -y curl jq qrencode cronie
      ;;
    apk)
      apk add --no-cache curl jq qrencode dcron
      ;;
    *)
      echo "Unsupported package manager."
      echo "Install these manually: curl jq qrencode cron"
      exit 1
      ;;
  esac

  if ! command -v yq >/dev/null 2>&1; then
    curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq
    chmod +x /usr/local/bin/yq
  fi
}

install_files() {
  install -m 755 "$SCRIPT_DIR/hyll-record.sh" /root/hyll-record.sh
  install -m 755 "$SCRIPT_DIR/hyll" /usr/local/bin/hyll
  install -m 755 "$SCRIPT_DIR/hydd" /usr/local/bin/hydd
  mkdir -p "$DATA_DIR"
  touch "$DATA_DIR/record.log"
}

setup_cron() {
  crontab -l 2>/dev/null | grep -v '/root/hyll-record.sh' > /tmp/hy_cron.tmp || true
  echo '*/5 * * * * /root/hyll-record.sh >> /root/hyll-data/record.log 2>&1' >> /tmp/hy_cron.tmp
  crontab /tmp/hy_cron.tmp
  rm -f /tmp/hy_cron.tmp
}

enable_cron() {
  if command -v systemctl >/dev/null 2>&1; then
    systemctl enable cron >/dev/null 2>&1 && systemctl restart cron >/dev/null 2>&1 && return 0
    systemctl enable crond >/dev/null 2>&1 && systemctl restart crond >/dev/null 2>&1 && return 0
  fi

  if command -v rc-update >/dev/null 2>&1; then
    rc-update add crond default >/dev/null 2>&1 || true
    service crond restart >/dev/null 2>&1 || true
  fi
}

main() {
  need_root
  need_hihy
  install_deps
  install_files
  setup_cron
  enable_cron

  /root/hyll-record.sh || true

  echo
  echo "Install completed."
  echo "Commands:"
  echo "  hyll"
  echo "  hydd"
  echo
}

main "$@"
