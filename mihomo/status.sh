#!/usr/bin/env bash
set -eu

CONFIG_DIR="${MIHOMO_CONFIG_DIR:-$HOME/.config/mihomo}"
LOG_FILE="$CONFIG_DIR/logs/mihomo.log"

if pgrep -u "$USER" -x mihomo >/dev/null 2>&1; then
    echo "mihomo: running"
    pgrep -a -u "$USER" -x mihomo | sed -n '1,5p'
else
    echo "mihomo: stopped"
fi

echo
echo "ports:"
ss -ltnp 2>/dev/null | grep -E ':(7890|9090)\b' || true

echo
echo "last logs:"
tail -n 40 "$LOG_FILE" 2>/dev/null || true
