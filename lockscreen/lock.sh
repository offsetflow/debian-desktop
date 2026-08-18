#!/bin/sh
set -eu

SCRIPT_PATH=$(readlink -f -- "$0")
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd)
REPO_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
STATE_DIR=${XDG_STATE_HOME:-"$HOME/.local/state"}/debian-desktop
STATE_FILE="$STATE_DIR/wallpaper"
DEFAULT_WALLPAPER="$REPO_DIR/wallpapers/wallhaven-o5zmwm_1920x1080.png"
FFMPEG_BIN=${FFMPEG_BIN:-ffmpeg}
I3LOCK_BIN=${I3LOCK_BIN:-i3lock-color}
PYTHON_BIN=${PYTHON_BIN:-python3}
preview_output=

if [ "${1:-}" = "--preview" ]; then
    if [ "$#" -ne 2 ]; then
        printf '%s\n' "usage: lock-screen --preview OUTPUT.png" >&2
        exit 2
    fi
    preview_output=$2
elif [ "$#" -ne 0 ]; then
    printf '%s\n' "usage: lock-screen [--preview OUTPUT.png]" >&2
    exit 2
fi

for command_name in "$FFMPEG_BIN" "$PYTHON_BIN"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'lock-screen: missing command: %s\n' "$command_name" >&2
        exit 1
    fi
done
if [ -z "$preview_output" ] && ! command -v "$I3LOCK_BIN" >/dev/null 2>&1; then
    printf 'lock-screen: missing command: %s\n' "$I3LOCK_BIN" >&2
    exit 1
fi

wallpaper=${LOCKSCREEN_WALLPAPER:-}
if [ -z "$wallpaper" ] && [ -r "$STATE_FILE" ]; then
    IFS= read -r wallpaper <"$STATE_FILE" || true
fi
if [ -z "$wallpaper" ] || [ ! -f "$wallpaper" ]; then
    wallpaper=$DEFAULT_WALLPAPER
fi

monitors=${LOCKSCREEN_MONITORS:-}
if [ -z "$monitors" ] && command -v xrandr >/dev/null 2>&1; then
    monitors=$(xrandr --current 2>/dev/null | awk '
        / connected/ {
            for (field = 1; field <= NF; field++) {
                if ($field ~ /^[0-9]+x[0-9]+[+][0-9]+[+][0-9]+/) {
                    print $field
                }
            }
        }
    ' || true)
fi
if [ -z "$monitors" ]; then
    monitors=1920x1080+0+0
fi

# i3lock-color's font sizes are global, so scale them from the first active
# monitor while keeping every element positioned per monitor by expressions.
primary_monitor=$(printf '%s\n' "$monitors" | sed -n '1p')
primary_height=$(printf '%s\n' "$primary_monitor" | sed -n 's/^[0-9][0-9]*x\([0-9][0-9]*\).*/\1/p')
if [ -z "$primary_height" ]; then
    primary_height=1080
fi
time_size=$((primary_height * 105 / 1000))
date_size=$((primary_height * 27 / 1000))
[ "$time_size" -ge 54 ] || time_size=54
[ "$date_size" -ge 17 ] || date_size=17

runtime_dir=${XDG_RUNTIME_DIR:-/tmp}
work_dir=$(mktemp -d "$runtime_dir/debian-desktop-lock.XXXXXX")
blurred="$work_dir/background.png"
lock_image="$work_dir/lock.png"

cleanup() {
    rm -f -- "$blurred" "$lock_image"
    rmdir -- "$work_dir" 2>/dev/null || true
}
trap cleanup EXIT HUP INT TERM

"$FFMPEG_BIN" -hide_banner -loglevel error -y \
    -i "$wallpaper" \
    -vf "gblur=sigma=18:steps=2,eq=brightness=-0.035:saturation=0.86" \
    -frames:v 1 -update 1 "$blurred"

"$PYTHON_BIN" "$SCRIPT_DIR/render.py" \
    --background "$blurred" \
    --output "$lock_image" \
    --monitors "$monitors"

if [ -n "$preview_output" ]; then
    cp -- "$lock_image" "$preview_output"
    printf '%s\n' "$preview_output"
    exit 0
fi

# The background renderer supplies only blur and contrast treatment.
# i3lock-color draws the clock itself, so both time and date keep updating.
LC_TIME=C "$I3LOCK_BIN" \
    --nofork \
    --ignore-empty-password \
    --image="$lock_image" \
    --force-clock \
    --no-unlock-indicator \
    --refresh-rate=1 \
    --time-str="%I:%M %p" \
    --date-str="%Y | %A" \
    --time-pos="x+w/2:y+h*0.205" \
    --date-pos="x+w/2:y+h*0.315" \
    --time-font="Comfortaa:style=Bold" \
    --date-font="Comfortaa:style=Bold" \
    --time-size="$time_size" \
    --date-size="$date_size" \
    --time-color="FFF0D6FF" \
    --date-color="A7A3FFFF" \
    --timeoutline-color="FFF0D6FF" \
    --timeoutline-width=1.6 \
    --no-modkey-text
