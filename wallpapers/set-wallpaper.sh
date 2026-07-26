#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEFAULT_WALLPAPER="$SCRIPT_DIR/wallhaven-o5zmwm_1920x1080.png"
STATE_DIR=${XDG_STATE_HOME:-"$HOME/.local/state"}/debian-desktop
STATE_FILE="$STATE_DIR/wallpaper"
wallpaper=${1:-}

# 未指定壁纸时恢复上次选择；状态无效时使用仓库内的默认壁纸。
if [ -z "$wallpaper" ] && [ -r "$STATE_FILE" ]; then
    IFS= read -r wallpaper <"$STATE_FILE" || true
fi
if [ -z "$wallpaper" ] || [ ! -f "$wallpaper" ]; then
    wallpaper=$DEFAULT_WALLPAPER
fi

if ! command -v feh >/dev/null 2>&1 || [ ! -f "$wallpaper" ]; then
    exit 0
fi

# 使用同一张壁纸分别填充每个显示器，保持比例并裁切多余区域。
feh --no-fehbg --bg-fill "$wallpaper"

# 只有主动选择壁纸时才更新状态；X11 启动时仅恢复已有选择。
if [ "$#" -gt 0 ]; then
    mkdir -p "$STATE_DIR"
    printf '%s\n' "$wallpaper" >"$STATE_FILE"
fi
