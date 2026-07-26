#!/bin/sh
set -eu

DWM_C=${1:-suckless/dwm/dwm.c}
DWM_DIR=$(dirname "$DWM_C")
CONFIG_H="$DWM_DIR/config.def.h"
CONFIG_MK="$DWM_DIR/config.mk"

# Overview 必须具备预览状态、入口函数、截图缩放和 XRender 链接。
grep -q "typedef struct Preview Preview;" "$DWM_C"
grep -q "static void previewallwin(const Arg \*arg);" "$DWM_C"
grep -q "static XImage \*getwindowximage(Client \*c);" "$DWM_C"
grep -q "static XImage \*scaledownimage(Client \*c" "$DWM_C"
grep -q "XK_a,[[:space:]]*previewallwin" "$CONFIG_H"
grep -q -- "-lXrender" "$CONFIG_MK"

# Overview 卡片必须统一使用 16:10 网格单元尺寸，截图缩放后填满卡片。
grep -q "c->preview.w = cardw;" "$DWM_C"
grep -q "c->preview.h = cardh;" "$DWM_C"
grep -q "image = scaledownimage(c, cardw, cardh);" "$DWM_C"
grep -q "rowoffset = (m->ww - rowwidth) / 2;" "$DWM_C"
