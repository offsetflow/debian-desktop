#!/bin/sh

# 结束旧的 Polybar，避免重复执行 startx 时出现多个状态栏实例。
polybar-msg cmd quit >/dev/null 2>&1 || true

# 等待旧进程退出，但不无限阻塞 X11 启动。
count=0
while pgrep -x polybar >/dev/null 2>&1 && [ "$count" -lt 20 ]; do
    sleep 0.1
    count=$((count + 1))
done

# 配置文件与脚本都保存在同一个 Git 仓库中。
CONFIG="$HOME/workspace/personal/debian-desktop/polybar/config.ini"

# 日志写入用户缓存目录，不进入 Git 仓库。
mkdir -p "$HOME/.cache/polybar"

# 每个已连接的显示器启动一个 Polybar 实例。
# Anybar 补丁会根据栏的位置，将每个实例绑定到对应的 dwm monitor，
# 从而让内置屏和外接屏都正确预留顶部空间。
polybar --list-monitors | cut -d: -f1 | while IFS= read -r monitor; do
    [ -n "$monitor" ] || continue

    MONITOR="$monitor" polybar --config="$CONFIG" main \
        >"$HOME/.cache/polybar/$monitor.log" 2>&1 &
done
