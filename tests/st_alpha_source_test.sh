#!/bin/sh
set -eu

ST_DIR=${1:-suckless/st}
PICOM_CONF=${2:-picom/picom.conf}

# 字体渲染细节交给系统 Fontconfig，st 只固定字体与像素尺寸。
font_pattern='JetBrains Mono:pixelsize=16'
grep -Fq "static char *font = \"$font_pattern\";" "$ST_DIR/config.def.h"

# st 必须自行控制默认背景透明度，前景文字仍保持完全不透明。
grep -q 'static float alpha = 0xd9 / 255.0f;' "$ST_DIR/config.def.h"
grep -Fq '[256] = "#26313b", /* background */' "$ST_DIR/config.def.h"
grep -Fq '[257] = "#e6edf3", /* foreground */' "$ST_DIR/config.def.h"
grep -q 'dc.col\[defaultbg\].color.alpha' "$ST_DIR/x.c"

# ARGB 窗口必须使用 32 位 TrueColor visual 和对应的 pixmap depth。
grep -q 'XMatchVisualInfo' "$ST_DIR/x.c"
grep -q 'xw.depth' "$ST_DIR/x.c"

# Picom 保持聚焦窗口清晰，并轻微降低未聚焦窗口的整体透明度。
focused=$(sed -n '/match = "focused || group_focused"/,/}/p' "$PICOM_CONF")
unfocused=$(sed -n '/match = "!focused && !group_focused/,/}/p' "$PICOM_CONF")
printf '%s\n' "$focused" | grep -q 'opacity = 1.0;'
printf '%s\n' "$unfocused" | grep -q 'opacity = 0.95;'

# st 保留自身的背景透明度，并单独启用毛玻璃模糊。
st_rule=$(sed -n '/match = "class_g ?= '\''st'\''"/,/}/p' "$PICOM_CONF")
printf '%s\n' "$st_rule" | grep -q 'opacity = 1.0;'
printf '%s\n' "$st_rule" | grep -q 'blur-background = true;'
printf '%s\n' "$st_rule" | grep -q 'blur-opacity = 1.0;'
