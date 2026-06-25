#!/usr/bin/env bash
set -eu

if pgrep -u "$USER" -x mihomo >/dev/null 2>&1; then
    pkill -u "$USER" -x mihomo
    echo "mihomo 已停止"
else
    echo "mihomo 未运行"
fi
