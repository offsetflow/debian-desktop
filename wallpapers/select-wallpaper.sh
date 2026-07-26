#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if ! command -v nsxiv >/dev/null 2>&1; then
    printf '%s\n' "select-wallpaper: nsxiv is not installed" >&2
    exit 1
fi

# nsxiv 以缩略图模式充当可视化筛选器：
# Shift+Q 输出当前图片；也可以用 m 标记图片后按 q 输出。
selected=$(
    find "$SCRIPT_DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
        -o -iname '*.gif' -o -iname '*.webp' \) \
        -print |
        LC_ALL=C sort |
        nsxiv -t -o -i |
        tail -n 1
)

[ -n "$selected" ] || exit 0
"$SCRIPT_DIR/set-wallpaper.sh" "$selected"
