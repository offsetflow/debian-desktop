#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

test_home="$test_root/home"
test_repo="$test_home/workspace/personal/debian-desktop"
test_bin="$test_root/bin"
captured_env="$test_root/dwm.env"

mkdir -p \
    "$test_repo/x11" \
    "$test_repo/mihomo" \
    "$test_repo/wallpapers" \
    "$test_repo/picom" \
    "$test_home/.local/bin" \
    "$test_bin"

cp "$repo_dir/x11/xinitrc" "$test_repo/x11/xinitrc"

for script in \
    "$test_repo/x11/setup-monitors.sh" \
    "$test_repo/mihomo/start.sh" \
    "$test_repo/wallpapers/set-wallpaper.sh" \
    "$test_repo/picom/launch.sh"; do
    printf '#!/bin/sh\nexit 0\n' >"$script"
    chmod +x "$script"
done

cat >"$test_bin/xrdb" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$test_bin/xrdb"

cat >"$test_bin/dbus-update-activation-environment" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$test_bin/dbus-update-activation-environment"

cat >"$test_home/.local/bin/dwm" <<'EOF'
#!/bin/sh
env >"$CAPTURED_ENV"
EOF
chmod +x "$test_home/.local/bin/dwm"

env \
    -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY \
    -u all_proxy -u ALL_PROXY -u no_proxy -u NO_PROXY \
    HOME="$test_home" \
    PATH="$test_bin:/usr/bin:/bin" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=$test_root/dbus" \
    CAPTURED_ENV="$captured_env" \
    "$test_repo/x11/xinitrc"

assert_env() {
    expected=$1
    if ! grep -Fxq "$expected" "$captured_env"; then
        printf 'missing dwm environment: %s\n' "$expected" >&2
        exit 1
    fi
}

assert_env 'http_proxy=http://127.0.0.1:7890'
assert_env 'https_proxy=http://127.0.0.1:7890'
assert_env 'HTTP_PROXY=http://127.0.0.1:7890'
assert_env 'HTTPS_PROXY=http://127.0.0.1:7890'
assert_env 'all_proxy=socks5://127.0.0.1:7890'
assert_env 'ALL_PROXY=socks5://127.0.0.1:7890'
assert_env 'no_proxy=127.0.0.1,localhost,::1'
assert_env 'NO_PROXY=127.0.0.1,localhost,::1'

env \
    -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY \
    -u all_proxy -u ALL_PROXY -u no_proxy -u NO_PROXY \
    HOME="$test_root/zsh-home" \
    zsh -c '
        source "$1" 2>/dev/null
        for name in \
            http_proxy https_proxy HTTP_PROXY HTTPS_PROXY \
            all_proxy ALL_PROXY no_proxy NO_PROXY; do
            if [[ -n ${(P)name+x} ]]; then
                print -u2 "zshrc unexpectedly sets proxy variable: $name"
                exit 1
            fi
        done
    ' zsh "$repo_dir/shell/zshrc"

printf '%s\n' "xinitrc proxy environment tests passed"
