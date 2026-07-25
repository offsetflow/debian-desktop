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

# 每个已连接的显示器启动一个 Polybar 实例。X11 同一会话只能有一个
# system tray，因此只让 xrandr 标记的主显示器加载 tray 模块。
monitors="$(polybar --list-monitors)"
primary_monitor="$(printf '%s\n' "$monitors" | awk '
    /\(primary\)/ {
        sub(/:.*/, "", $1)
        print $1
        exit
    }
')"
if [ -z "$primary_monitor" ]; then
    primary_monitor="$(printf '%s\n' "$monitors" | sed -n '1s/:.*//p')"
fi

printf '%s\n' "$monitors" | while IFS= read -r monitor_line; do
    monitor="${monitor_line%%:*}"
    [ -n "$monitor" ] || continue

    right_modules="input-method brightness pulseaudio wlan battery power"
    if [ "$monitor" = "$primary_monitor" ]; then
        right_modules="tray $right_modules"
    fi

    MONITOR="$monitor" POLYBAR_RIGHT_MODULES="$right_modules" \
        polybar --config="$CONFIG" main \
        >"$HOME/.cache/polybar/$monitor.log" 2>&1 &
done
