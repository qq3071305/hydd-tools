# hydd-tools

Small helper scripts for Hi_Hysteria:

- `hyll-record.sh`: collect monthly traffic snapshots every 5 minutes
- `hyll`: show realtime and monthly traffic
- `hydd`: manage users, view configs/QR codes, and clear stats
- `hy-install.sh`: install the scripts onto a server that already has Hi_Hysteria

## Install

Clone this repository onto a server where Hi_Hysteria is already installed, then run:

```bash
chmod +x hy-install.sh
sudo ./hy-install.sh
```

The installer will:

- copy `hyll-record.sh` to `/root/hyll-record.sh`
- copy `hyll` and `hydd` to `/usr/local/bin`
- create `/root/hyll-data`
- register a cron task to collect stats every 5 minutes
- enable and restart cron when possible

## Commands

```bash
hyll
hyll 2026-05
hydd
```

## Requirements

- A working Hi_Hysteria install with `/etc/hihy/conf/config.yaml`
- `curl`
- `jq`
- `yq`
- `qrencode` for QR display in `hydd`
