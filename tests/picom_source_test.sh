#!/bin/sh
set -eu

PICOM_CONF=${1:-picom/picom.conf}

# 单窗口平铺时，dwm 会把边框宽度降为 0；picom 应据此去掉圆角。
grep -q 'match = "border_width = 0"' "$PICOM_CONF"
grep -q 'corner-radius = 0;' "$PICOM_CONF"

# 保留动画，但避免全屏切换合成器和对大型 Chromium/Electron 窗口执行
# 昂贵的 geometry-change 动画。
grep -q '^unredir-if-possible = false;' "$PICOM_CONF"
grep -q '^blur-background = false;' "$PICOM_CONF"
grep -q '^blur-strength = 6;' "$PICOM_CONF"
grep -q 'duration = 0.14;' "$PICOM_CONF"
grep -q 'duration = 0.12;' "$PICOM_CONF"
grep -q 'duration = 0.10;' "$PICOM_CONF"
grep -q "class_g != 'Google-chrome'" "$PICOM_CONF"
grep -q "class_g != 'Chatgpt'" "$PICOM_CONF"
grep -q "class_g != 'Marktext'" "$PICOM_CONF"
