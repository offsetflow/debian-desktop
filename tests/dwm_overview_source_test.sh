#!/bin/sh
set -eu

DWM_C=${1:-suckless/dwm/dwm.c}
DWM_DIR=$(dirname "$DWM_C")
CONFIG_H="$DWM_DIR/config.def.h"
CONFIG_MK="$DWM_DIR/config.mk"

# Overview 必须具备预览状态、入口函数、服务端缩放和 XRender 链接。
grep -q "typedef struct Preview Preview;" "$DWM_C"
grep -q "static void previewallwin(const Arg \*arg);" "$DWM_C"
grep -q "static Pixmap createpreviewpixmap(Client \*c" "$DWM_C"
grep -q "XK_a,[[:space:]]*previewallwin" "$CONFIG_H"
grep -q -- "-lXrender" "$CONFIG_MK"

# Overview 卡片必须统一使用 16:10 网格单元尺寸，并由 XRender 直接缩放到
# 服务端 Pixmap，避免全尺寸 XGetImage 和逐像素 CPU 循环。
grep -q "c->preview.w = cardw;" "$DWM_C"
grep -q "c->preview.h = cardh;" "$DWM_C"
grep -q "pixmap = createpreviewpixmap(c, cardw, cardh);" "$DWM_C"
grep -q "XRenderSetPictureTransform" "$DWM_C"
grep -q "XRenderSetPictureFilter" "$DWM_C"
! grep -q "XGetPixel" "$DWM_C"
! grep -q "XPutPixel" "$DWM_C"
grep -q "rowoffset = (m->ww - rowwidth) / 2;" "$DWM_C"

# 用一个遮罩层覆盖真实窗口，不能通过批量 Unmap/Map 触发 Picom 动画风暴。
grep -q 'DwmOverviewBackdrop' "$DWM_C"
grep -q 'DwmOverviewCard' "$DWM_C"
setpreview_body=$(sed -n '/^setpreviewwins(Monitor \*m)/,/^}/p' "$DWM_C")
clearoverview_body=$(sed -n '/^clearoverview(Monitor \*m, Client \*selected)/,/^}/p' "$DWM_C")
! printf '%s\n' "$setpreview_body" | grep -q 'XUnmapWindow(dpy, c->win)'
! printf '%s\n' "$clearoverview_body" | grep -q 'XMapWindow(dpy, c->win)'
