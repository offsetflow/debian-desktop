#!/bin/sh
set -eu

DWM_C=${1:-suckless/dwm/dwm.c}
CONFIG_H="$(dirname "$DWM_C")/config.h"

# 最小 gaps：配置、开关和统一调整函数必须存在。
grep -q "static const unsigned int gappih" "$CONFIG_H"
grep -q "static const unsigned int gappiv" "$CONFIG_H"
grep -q "static const unsigned int gappoh" "$CONFIG_H"
grep -q "static const unsigned int gappov" "$CONFIG_H"
grep -q "static const int smartgaps" "$CONFIG_H"
grep -q "static void togglegaps(const Arg \*arg);" "$DWM_C"
grep -q "static void incrgaps(const Arg \*arg);" "$DWM_C"
grep -q "XK_g,[[:space:]]*togglegaps" "$CONFIG_H"
