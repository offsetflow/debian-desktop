#!/bin/sh
set -eu

PICOM_CONF=${1:-picom/picom.conf}

# 单窗口平铺时，dwm 会把边框宽度降为 0；picom 应据此去掉圆角。
grep -q 'match = "border_width = 0"' "$PICOM_CONF"
grep -q 'corner-radius = 0;' "$PICOM_CONF"
