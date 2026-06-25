#!/usr/bin/env bash
set -eu

# 用户级安装 mihomo core，不写 /usr/local，不依赖 systemd。
# 订阅 URL 不进入 Git：默认从 /tmp/vpn 读取。

MIHOMO_BIN="$HOME/.local/bin/mihomo"
CONFIG_DIR="$HOME/.config/mihomo"
DESKTOP_DIR="$HOME/workspace/personal/debian-desktop"
UPDATE_SCRIPT="$DESKTOP_DIR/mihomo/update-profile.sh"

mkdir -p "$HOME/.local/bin" "$CONFIG_DIR" "$CONFIG_DIR/profiles" "$CONFIG_DIR/logs"

echo "==> 查询 mihomo 最新版本"
release_json="$(mktemp)"
curl -fsSL https://api.github.com/repos/MetaCubeX/mihomo/releases/latest -o "$release_json"
tag="$(jq -r '.tag_name' "$release_json")"
asset_url="$(jq -r '.assets[] | select(.name | test("linux-amd64-compatible.*gz$")) | .browser_download_url' "$release_json" | head -1)"

if [ -z "$asset_url" ] || [ "$asset_url" = "null" ]; then
    echo "没有找到 linux-amd64-compatible mihomo 下载资源" >&2
    exit 1
fi

echo "==> 最新版本：$tag"
echo "==> 下载资源：${asset_url##*/}"

tmp_dir="$(mktemp -d)"
archive="$tmp_dir/mihomo.gz"
binary="$tmp_dir/mihomo"

curl -fL --retry 3 --connect-timeout 20 "$asset_url" -o "$archive"
gzip -dc "$archive" > "$binary"
chmod +x "$binary"
mv "$binary" "$MIHOMO_BIN"

echo "==> 已安装：$MIHOMO_BIN"
"$MIHOMO_BIN" -v

if [ ! -f "$CONFIG_DIR/config.yaml" ]; then
    cat > "$CONFIG_DIR/config.yaml" <<'YAML'
mixed-port: 7890
allow-lan: false
mode: rule
log-level: info
external-controller: 127.0.0.1:9090
secret: ""

proxies: []
proxy-groups:
  - name: PROXY
    type: select
    proxies:
      - DIRECT
rules:
  - MATCH,DIRECT
YAML
    echo "==> 已创建默认配置：$CONFIG_DIR/config.yaml"
fi

if [ -s /tmp/vpn ]; then
    echo "==> 检测到 /tmp/vpn，开始导入订阅"
    "$UPDATE_SCRIPT" /tmp/vpn
else
    echo "==> 未检测到 /tmp/vpn，跳过订阅导入"
fi

echo
echo "准备完成。常用命令："
echo "$DESKTOP_DIR/mihomo/start.sh"
echo "$DESKTOP_DIR/mihomo/status.sh"
echo "$DESKTOP_DIR/mihomo/stop.sh"
