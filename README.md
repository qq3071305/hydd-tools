# hydd-tools

给 Hi_Hysteria 使用的一组中文化辅助脚本，包含安装、用户管理、流量查看和月度统计能力。

快速使用：

```bash
git clone https://github.com/qq3071305/hydd-tools
cd hydd-tools
chmod +x hy-install.sh
sudo ./hy-install.sh
```

安装完成后可直接使用：

```bash
hydd
hyll
hyll 2026-05
```

## 功能说明

- `hy-install.sh`：安装脚本，会复制文件、安装依赖并注册定时任务
- `hydd`：主脚本，既可交互管理用户，也可直接查看实时流量、月度流量和 Hy2 端口流量
- `hyll`：兼容入口，内部转发到 `hydd`
- `hyll-record.sh`：每 5 分钟采集一次流量快照并累计到月度统计

## 安装

先把仓库克隆到已经安装好 Hi_Hysteria 的服务器上，然后执行：

```bash
chmod +x hy-install.sh
sudo ./hy-install.sh
```

安装脚本会自动：

- 把 `hyll-record.sh` 复制到 `/root/hyll-record.sh`
- 把 `hyll` 和 `hydd` 复制到 `/usr/local/bin`
- 创建 `/root/hyll-data`
- 注册每 5 分钟采集一次统计数据的 `cron` 任务
- 在支持的系统上启用并重启 `cron`
- 自动安装 `curl`、`jq`、`qrencode` 和 `yq`

## 常用命令

```bash
hydd
hydd dashboard
hydd watch
hydd month 2026-05
hydd hy2
hyll
hyll 2026-05
```

## 使用说明

`hydd` 菜单主要用于：

- 添加用户
- 删除用户
- 查看已启用和已禁用用户
- 查看实时流量和月度流量
- 查看 Hy2 端口流量（更接近服务商计费）
- 导出用户配置到 `/root`
- 显示用户二维码
- 清空实时统计和月度统计
- 修改密码
- 禁用或启用用户

`hydd` 也支持直接命令模式：

- `hydd dashboard`：查看在线用户、实时流量和本月累计
- `hydd watch [秒]`：实时监控，默认每 3 秒刷新
- `hydd month 2026-05`：查看指定月份累计
- `hydd hy2`：查看 Hy2 端口流量

`hyll` 保留为兼容入口：

- `hyll` 等价于 `hydd dashboard`
- `hyll watch` 等价于 `hydd watch`
- `hyll 2026-05` 等价于 `hydd month 2026-05`

## 依赖要求

- 已正常安装 Hi_Hysteria，并存在 `/etc/hihy/conf/config.yaml`
- `curl`
- `jq`
- `yq`
- `qrencode`

## 数据位置

- 月度统计目录：`/root/hyll-data`
- 月度统计文件：`/root/hyll-data/YYYY-MM.json`
- 实时采集脚本：`/root/hyll-record.sh`

## 说明

- 当前脚本界面已经中文化
- 配置变更后如果重启失败，会自动回滚到修改前的配置
- 安装脚本支持常见 Linux 包管理器
- `yq` 下载已兼容 `amd64`、`arm64` 和 `arm`
