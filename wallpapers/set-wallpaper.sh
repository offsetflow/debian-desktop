#!/bin/sh

# 使用同一张超宽壁纸分别填充每个显示器。
# --bg-fill 保持图片比例并裁切多余区域，避免拉伸变形。
WALLPAPER="$HOME/workspace/personal/debian-desktop/wallpapers/wallhaven-gw2gyq-1920x1080.png"

if command -v feh >/dev/null 2>&1 && [ -f "$WALLPAPER" ]; then
    feh --no-fehbg --bg-fill "$WALLPAPER"
fi
