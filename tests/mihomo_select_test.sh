#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
selector="$repo_dir/mihomo/select.sh"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

stub_dir="$tmp_dir/bin"
put_log="$tmp_dir/put.log"
menu_count="$tmp_dir/menu.count"
menu_args="$tmp_dir/menu.args"
mkdir -p "$stub_dir"

cat >"$tmp_dir/proxies.json" <<'EOF'
{
  "proxies": {
    "GLOBAL": {"type": "Selector", "now": "DIRECT", "all": ["DIRECT", "手动 选择"]},
    "手动 选择": {"type": "Selector", "now": "香港 \"A\"", "all": ["香港 \"A\"", "日本 B"]},
    "自动选择": {"type": "URLTest", "now": "日本 B", "all": ["香港 \"A\"", "日本 B"]}
  }
}
EOF

cat >"$stub_dir/curl" <<'EOF'
#!/bin/bash
set -e
if [[ ${CURL_FAIL:-0} == 1 ]]; then
    exit 7
fi
method=GET
data=
url=
while (($#)); do
    case "$1" in
        -X) method=$2; shift 2 ;;
        --data) data=$2; shift 2 ;;
        -H|-w) shift 2 ;;
        -*) shift ;;
        *) url=$1; shift ;;
    esac
done
if [[ $method == GET ]]; then
    cat "$API_RESPONSE_FILE"
else
    printf 'url=%s\njson=%s\n' "$url" "$data" >>"$PUT_LOG"
fi
EOF

cat >"$stub_dir/fzf" <<'EOF'
#!/bin/bash
count=0
[[ -f $MENU_COUNT ]] && count=$(<"$MENU_COUNT")
count=$((count + 1))
printf '%s\n' "$count" >"$MENU_COUNT"
if [[ $count == 1 ]]; then
    [[ -n ${GROUP_CHOICE:-} ]] || exit 1
    printf '%s\n' "$GROUP_CHOICE"
else
    [[ -n ${NODE_CHOICE:-} ]] || exit 1
    printf '%s\n' "$NODE_CHOICE"
fi
EOF

cat >"$stub_dir/dmenu" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >>"$MENU_ARGS"
count=0
[[ -f $MENU_COUNT ]] && count=$(<"$MENU_COUNT")
count=$((count + 1))
printf '%s\n' "$count" >"$MENU_COUNT"
if [[ $count == 1 ]]; then
    printf '%s\n' "$GROUP_CHOICE"
else
    printf '%s\n' "$NODE_CHOICE"
fi
EOF
chmod +x "$stub_dir/curl" "$stub_dir/fzf" "$stub_dir/dmenu"

run_selector() {
    API_RESPONSE_FILE="$tmp_dir/proxies.json" \
    PUT_LOG="$put_log" \
    MENU_COUNT="$menu_count" \
    MENU_ARGS="$menu_args" \
    PATH="$stub_dir:/usr/bin:/bin" \
    MIHOMO_API_URL="http://127.0.0.1:19090" \
        "$selector" "$@"
}

# Direct arguments must safely encode both the URL path and JSON node name.
: >"$put_log"
run_selector '手动 选择' '香港 "A"' >"$tmp_dir/direct.out"
grep -Fqx 'url=http://127.0.0.1:19090/proxies/%E6%89%8B%E5%8A%A8%20%E9%80%89%E6%8B%A9' "$put_log"
grep -Fqx 'json={"name":"香港 \"A\""}' "$put_log"
grep -Fqx 'mihomo: 手动 选择 -> 香港 "A"' "$tmp_dir/direct.out"

# Terminal mode chooses the group and node through fzf.
: >"$put_log"
rm -f "$menu_count"
GROUP_CHOICE='手动 选择' NODE_CHOICE='日本 B' run_selector
grep -Fqx 'json={"name":"日本 B"}' "$put_log"
[[ $(<"$menu_count") == 2 ]]

# X11 mode prefers dmenu and produces the same PUT.
: >"$put_log"
: >"$menu_args"
rm -f "$menu_count"
DISPLAY=:0 GROUP_CHOICE='手动 选择' NODE_CHOICE='日本 B' run_selector --monitor 1
grep -Fqx 'json={"name":"日本 B"}' "$put_log"
[[ $(<"$menu_count") == 2 ]]
[[ $(grep -Fxc -- '-m 1 -i -p Mihomo group' "$menu_args") == 1 ]]
[[ $(grep -Fxc -- '-m 1 -i -p Mihomo node' "$menu_args") == 1 ]]

# Cancelling the first menu is successful and sends no PUT.
: >"$put_log"
rm -f "$menu_count"
GROUP_CHOICE= NODE_CHOICE= run_selector
[[ ! -s "$put_log" ]]

# Invalid groups and nodes fail before PUT.
if run_selector 自动选择 '日本 B' >"$tmp_dir/error.out" 2>&1; then
    echo "non-Selector group unexpectedly succeeded" >&2
    exit 1
fi
grep -Fq 'mihomo-select: unknown Selector group: 自动选择' "$tmp_dir/error.out"

if run_selector '手动 选择' '不存在' >"$tmp_dir/error.out" 2>&1; then
    echo "unknown node unexpectedly succeeded" >&2
    exit 1
fi
grep -Fq 'mihomo-select: node is not in 手动 选择: 不存在' "$tmp_dir/error.out"

# API errors and a response without Selector groups are explicit.
if CURL_FAIL=1 run_selector >"$tmp_dir/error.out" 2>&1; then
    echo "unavailable API unexpectedly succeeded" >&2
    exit 1
fi
grep -Fq 'mihomo-select: cannot reach http://127.0.0.1:19090' "$tmp_dir/error.out"

printf '%s\n' '{"proxies":{"自动":{"type":"URLTest","all":["A"]}}}' >"$tmp_dir/no-selector.json"
if API_RESPONSE_FILE="$tmp_dir/no-selector.json" \
    PUT_LOG="$put_log" MENU_COUNT="$menu_count" \
    PATH="$stub_dir:/usr/bin:/bin" MIHOMO_API_URL=http://127.0.0.1:19090 \
    "$selector" >"$tmp_dir/error.out" 2>&1
then
    echo "empty Selector list unexpectedly succeeded" >&2
    exit 1
fi
grep -Fq 'mihomo-select: no Selector groups found' "$tmp_dir/error.out"

# Interactive mode needs at least one chooser.
chooserless_dir="$tmp_dir/chooserless"
mkdir -p "$chooserless_dir"
ln -s "$stub_dir/curl" "$chooserless_dir/curl"
ln -s "$(command -v jq)" "$chooserless_dir/jq"
ln -s "$(command -v bash)" "$chooserless_dir/bash"
ln -s "$(command -v cat)" "$chooserless_dir/cat"
if API_RESPONSE_FILE="$tmp_dir/proxies.json" \
    PUT_LOG="$put_log" PATH="$chooserless_dir" \
    MIHOMO_API_URL=http://127.0.0.1:19090 \
    "$selector" >"$tmp_dir/error.out" 2>&1
then
    echo "interactive selection unexpectedly succeeded without a chooser" >&2
    exit 1
fi
grep -Fq 'mihomo-select: neither dmenu nor fzf is available' "$tmp_dir/error.out"

printf '%s\n' "mihomo select tests passed"
