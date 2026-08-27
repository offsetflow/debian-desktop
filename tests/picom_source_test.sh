#!/bin/sh
set -eu

PICOM_CONF=${1:-picom/picom.conf}

# 单窗口平铺时，dwm 会把边框宽度降为 0；picom 应据此去掉圆角。
grep -q 'match = "border_width = 0"' "$PICOM_CONF"
grep -q 'corner-radius = 0;' "$PICOM_CONF"

# 保留短促的窗口开关动画，但禁用会让 dwm 平铺布局产生输入延迟感的
# geometry-change 动画；Alt+A 的内部窗口应近乎即时显示。
grep -q '^unredir-if-possible = false;' "$PICOM_CONF"
grep -q '^blur-background = false;' "$PICOM_CONF"
grep -q '^blur-strength = 6;' "$PICOM_CONF"
grep -q 'duration = 0.10;' "$PICOM_CONF"
grep -q 'duration = 0.08;' "$PICOM_CONF"
! grep -q 'geometry-change' "$PICOM_CONF"
grep -q "class_g = 'DwmOverviewBackdrop' || class_g = 'DwmOverviewCard'" "$PICOM_CONF"
grep -q 'duration = 0.01;' "$PICOM_CONF"
