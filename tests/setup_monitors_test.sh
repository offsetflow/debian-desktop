#!/bin/sh

set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
script="$repo_dir/x11/setup-monitors.sh"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

cat >"$tmp_dir/xrandr" <<'EOF'
#!/bin/sh
if [ "${1:-}" = "--query" ]; then
    if [ "${XRANDR_SCENARIO:-dual}" = "internal" ]; then
        cat <<'OUTPUT'
Screen 0: minimum 8 x 8, current 2560 x 1600, maximum 32767 x 32767
DP-2 connected primary 2560x1600+0+0 (normal left inverted right x axis y axis) 344mm x 194mm
OUTPUT
        exit 0
    fi
    cat <<'OUTPUT'
Screen 0: minimum 8 x 8, current 4480 x 1440, maximum 32767 x 32767
DP-2 connected 2560x1600+1920+0 (normal left inverted right x axis y axis) 344mm x 194mm
HDMI-0 connected 1920x1080+0+0 (normal left inverted right x axis y axis) 527mm x 296mm
DP-1 disconnected (normal left inverted right x axis y axis)
OUTPUT
    exit 0
fi

printf '%s\n' "$*" >>"$XRANDR_LOG"
EOF
chmod +x "$tmp_dir/xrandr"

export PATH="$tmp_dir:$PATH"
export XRANDR_LOG="$tmp_dir/xrandr.log"
export XRANDR_SCENARIO=dual

: >"$XRANDR_LOG"
"$script" left
grep -Fx -- '--output HDMI-0 --primary --auto --left-of DP-2 --output DP-2 --auto' "$XRANDR_LOG" >/dev/null

: >"$XRANDR_LOG"
"$script" right
grep -Fx -- '--output HDMI-0 --primary --auto --right-of DP-2 --output DP-2 --auto' "$XRANDR_LOG" >/dev/null

: >"$XRANDR_LOG"
XRANDR_SCENARIO=internal "$script" left
grep -Fx -- '--output DP-2 --primary --auto' "$XRANDR_LOG" >/dev/null

if "$script" top >/dev/null 2>&1; then
    echo "invalid position unexpectedly succeeded" >&2
    exit 1
fi

echo "setup-monitors tests passed"
