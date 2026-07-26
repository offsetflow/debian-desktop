#!/bin/sh
set -eu

DWM_C=${1:-suckless/dwm/dwm.c}
CONFIG_H="$(dirname "$DWM_C")/config.def.h"

# Magic Grid 必须注册布局函数与快捷键。
grep -q "static void magicgrid(Monitor \*m);" "$DWM_C"
grep -q "^magicgrid(Monitor \*m)" "$DWM_C"
grep -q "{ \"###\",[[:space:]]*magicgrid }" "$CONFIG_H"
grep -q "XK_space,[[:space:]]*setlayout,[[:space:]]*{.v = &layouts\[3\]}" "$CONFIG_H"
