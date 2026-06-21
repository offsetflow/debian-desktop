#!/bin/sh
set -eu

DWM_C=${1:-suckless/dwm/dwm.c}

# 新窗口必须通过尾插函数进入客户端链表，避免抢占主窗口。
grep -q "static void attachbottom(Client \*c);" "$DWM_C"
grep -q "^attachbottom(Client \*c)" "$DWM_C"

# manage() 应使用尾插；pop() 仍使用头插 attach()，以保留 zoom 行为。
manage_body=$(sed -n "/^manage(Window w/,/^}/p" "$DWM_C")
pop_body=$(sed -n "/^pop(Client \*c)/,/^}/p" "$DWM_C")
printf "%s\n" "$manage_body" | grep -q "attachbottom(c);"
printf "%s\n" "$pop_body" | grep -q "attach(c);"
