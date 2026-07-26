#!/usr/bin/env bash
set -eu

MIHOMO_BIN="${MIHOMO_BIN:-$HOME/.local/bin/mihomo}"
CONFIG_DIR="${MIHOMO_CONFIG_DIR:-$HOME/.config/mihomo}"
CONFIG_FILE="$CONFIG_DIR/config.yaml"
LOG_FILE="$CONFIG_DIR/logs/mihomo.log"
CONTROLLER_ADDRESS="${MIHOMO_CONTROLLER_ADDRESS:-127.0.0.1:9090}"

if [ ! -x "$MIHOMO_BIN" ]; then
    echo "mihomo 不存在：$MIHOMO_BIN" >&2
    echo "请先执行：~/workspace/personal/debian-desktop/scripts/prepare-mihomo.sh" >&2
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "配置文件不存在：$CONFIG_FILE" >&2
    exit 1
fi

mkdir -p "$CONFIG_DIR/logs"

if pgrep -u "$USER" -x mihomo >/dev/null 2>&1; then
    echo "mihomo 已在运行"
    exit 0
fi

nohup "$MIHOMO_BIN" \
    -d "$CONFIG_DIR" \
    -f "$CONFIG_FILE" \
    -ext-ctl "$CONTROLLER_ADDRESS" \
    -secret "" \
    >"$LOG_FILE" 2>&1 &
echo "mihomo 已启动，日志：$LOG_FILE"
