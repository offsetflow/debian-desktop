#!/usr/bin/env bash
set -eu

# 从一个只包含订阅 URL 的文件下载 mihomo/clash YAML 配置。
# 默认读取 /tmp/vpn。脚本不会打印 URL，避免订阅泄露到终端日志。

URL_FILE="${1:-/tmp/vpn}"
CONFIG_DIR="${MIHOMO_CONFIG_DIR:-$HOME/.config/mihomo}"
PROFILE_DIR="$CONFIG_DIR/profiles"
CONFIG_FILE="$CONFIG_DIR/config.yaml"
PROFILE_FILE="$PROFILE_DIR/subscription.yaml"

if [ ! -s "$URL_FILE" ]; then
    echo "订阅 URL 文件不存在或为空：$URL_FILE" >&2
    exit 1
fi

mkdir -p "$PROFILE_DIR"
tmp="$(mktemp)"

echo "==> 下载订阅配置，不显示 URL"
url="$(tr -d '\r\n' < "$URL_FILE")"
curl -fL --retry 3 --connect-timeout 20 "$url" -o "$tmp"

if ! grep -Eq '^(proxies|proxy-providers|proxy-groups|rules|mixed-port|port|socks-port):' "$tmp"; then
    echo "下载内容看起来不像 mihomo/clash YAML 配置，已停止导入" >&2
    exit 1
fi

cp "$tmp" "$PROFILE_FILE"

if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
fi

cp "$PROFILE_FILE" "$CONFIG_FILE"

echo "==> 已导入订阅配置：$CONFIG_FILE"
echo "==> 上一次配置备份：$CONFIG_FILE.bak"
