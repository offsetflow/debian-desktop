#!/bin/sh
set -eu

DWM_C=${1:-suckless/dwm/dwm.c}
CONFIG_H="$(dirname "$DWM_C")/config.def.h"

# 最小 gaps：配置、开关和统一调整函数必须存在。
grep -q "static const unsigned int gappih" "$CONFIG_H"
grep -q "static const unsigned int gappiv" "$CONFIG_H"
grep -q "static const unsigned int gappoh" "$CONFIG_H"
grep -q "static const unsigned int gappov" "$CONFIG_H"
grep -q "static const int smartgaps" "$CONFIG_H"
grep -q "static void togglegaps(const Arg \*arg);" "$DWM_C"
grep -q "static void incrgaps(const Arg \*arg);" "$DWM_C"
grep -q "XK_g,[[:space:]]*togglegaps" "$CONFIG_H"

# 单窗口平铺时必须统一关闭 gaps 与边框。
grep -q "static unsigned int numtiledvisible(Monitor \*m);" "$DWM_C"
grep -q "static int isfullscreenlikefloating(Client \*c);" "$DWM_C"
grep -q "static int shouldhideborder(Client \*c);" "$DWM_C"
grep -q "static void syncborder(Client \*c);" "$DWM_C"
grep -q "^syncborder(Client \*c)" "$DWM_C"
grep -q "XConfigureWindow(dpy, c->win, CWBorderWidth, &wc);" "$DWM_C"
grep -q "^numtiledvisible(Monitor \*m)" "$DWM_C"
grep -q "^isfullscreenlikefloating(Client \*c)" "$DWM_C"
grep -q "^shouldhideborder(Client \*c)" "$DWM_C"
grep -q "c->isfloating && !c->isfullscreen" "$DWM_C"
grep -q "c->x == c->mon->wx" "$DWM_C"
grep -q "c->y == c->mon->wy" "$DWM_C"
grep -q "WIDTH(c) == c->mon->ww" "$DWM_C"
grep -q "HEIGHT(c) == c->mon->wh" "$DWM_C"
grep -q "isfullscreenlikefloating(c)" "$DWM_C"
grep -q "XSetWindowBorder(dpy, c->win, shouldhideborder(c)" "$DWM_C"
grep -q "syncborder(c);" "$DWM_C"
grep -q "resize(c, m->wx, m->wy, m->ww - 2 \* (shouldhideborder(c) ? 0 : c->bw), m->wh - 2 \* (shouldhideborder(c) ? 0 : c->bw), 0);" "$DWM_C"
