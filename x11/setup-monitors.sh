#!/bin/sh

set -eu

position=${1:-left}

case "$position" in
    left|right) ;;
    *)
        echo "usage: $0 [left|right]" >&2
        exit 2
        ;;
esac

if ! command -v xrandr >/dev/null 2>&1; then
    echo "setup-monitors: xrandr is not installed" >&2
    exit 1
fi

connected_outputs=$(xrandr --query | awk '$2 == "connected" { print $1 }')
internal_output=
external_output=

# 优先使用标准的笔记本面板名称，避免把 DisplayPort 外屏误判为内屏。
for output in $connected_outputs; do
    case "$output" in
        eDP*|LVDS*|DSI*)
            internal_output=$output
            break
            ;;
    esac
done

# NVIDIA 驱动可能把笔记本内屏命名为 DP-*；仅在没有标准名称时回退。
if [ -z "$internal_output" ]; then
    for output in $connected_outputs; do
        case "$output" in
            DP-*)
                internal_output=$output
                break
                ;;
        esac
    done
fi

if [ -z "$internal_output" ]; then
    echo "setup-monitors: no connected laptop display found" >&2
    exit 1
fi

for output in $connected_outputs; do
    if [ "$output" != "$internal_output" ]; then
        external_output=$output
        break
    fi
done

if [ -z "$external_output" ]; then
    xrandr --output "$internal_output" --primary --auto
    exit 0
fi

case "$position" in
    left)
        xrandr \
            --output "$external_output" --primary --auto --left-of "$internal_output" \
            --output "$internal_output" --auto
        ;;
    right)
        xrandr \
            --output "$external_output" --primary --auto --right-of "$internal_output" \
            --output "$internal_output" --auto
        ;;
esac
