#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="/etc/hihy/conf/config.yaml"
DATA_DIR="/root/hyll-data"

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "请使用 root 用户运行"
    exit 1
  fi
}

need_hihy() {
  [ -f "$CONFIG_FILE" ] || {
    echo "未找到 Hi_Hysteria 配置文件：$CONFIG_FILE"
    echo "请先安装 Hi_Hysteria，再运行此安装脚本。"
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

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    armv7l|armv6l) echo "arm" ;;
    *)
      echo "unknown"
      ;;
  esac
}

install_deps() {
  local pm arch yq_url
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
      echo "暂不支持当前包管理器。"
      echo "请手动安装这些依赖：curl jq qrencode cron"
      exit 1
      ;;
  esac

  if ! command -v yq >/dev/null 2>&1; then
    arch="$(detect_arch)"
    case "$arch" in
      amd64) yq_url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" ;;
      arm64) yq_url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_arm64" ;;
      arm) yq_url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_arm" ;;
      *)
        echo "无法识别当前 CPU 架构，请手动安装 yq。"
        exit 1
        ;;
    esac

    curl -fsSL "$yq_url" -o /usr/local/bin/yq
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
  echo "安装完成。"
  echo "可用命令："
  echo "  hyll"
  echo "  hydd"
  echo
}

main "$@"
