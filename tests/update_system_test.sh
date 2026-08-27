#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

stub_dir="$test_root/bin"
modules_dir="$test_root/modules"
target_kernel=6.12.999-test-amd64
command_log="$test_root/commands.log"
mkdir -p "$stub_dir" \
    "$modules_dir/$target_kernel/build" \
    "$modules_dir/$target_kernel/updates/dkms" \
    "$test_root/boot"
touch "$modules_dir/$target_kernel/updates/dkms/nvidia-current.ko.xz"
touch "$test_root/boot/vmlinuz-$target_kernel"
ln -s "$test_root/boot/vmlinuz-$target_kernel" "$test_root/vmlinuz"

cat >"$stub_dir/sudo" <<'EOF'
#!/bin/sh
printf 'sudo' >>"$COMMAND_LOG"
printf ' %s' "$@" >>"$COMMAND_LOG"
printf '\n' >>"$COMMAND_LOG"
[ "${1:-}" = -v ] && exit 0
exec "$@"
EOF

cat >"$stub_dir/apt-get" <<'EOF'
#!/bin/sh
printf 'apt-get' >>"$COMMAND_LOG"
printf ' %s' "$@" >>"$COMMAND_LOG"
printf '\n' >>"$COMMAND_LOG"
EOF

cat >"$stub_dir/dkms" <<EOF
#!/bin/sh
if [ "\${1:-}" = status ]; then
    printf '%s\n' 'nvidia-current/550.test, $target_kernel, x86_64: installed'
    exit 0
fi
printf 'dkms' >>"\$COMMAND_LOG"
printf ' %s' "\$@" >>"\$COMMAND_LOG"
printf '\n' >>"\$COMMAND_LOG"
EOF

cat >"$stub_dir/depmod" <<'EOF'
#!/bin/sh
printf 'depmod' >>"$COMMAND_LOG"
printf ' %s' "$@" >>"$COMMAND_LOG"
printf '\n' >>"$COMMAND_LOG"
EOF

cat >"$stub_dir/dpkg-query" <<'EOF'
#!/bin/sh
printf 'ii '
EOF

cat >"$stub_dir/mihomo-start" <<'EOF'
#!/bin/sh
printf '%s\n' 'mihomo-start' >>"$COMMAND_LOG"
EOF

cat >"$stub_dir/uname" <<'EOF'
#!/bin/sh
printf '%s\n' '6.12.90-old-amd64'
EOF

chmod +x "$stub_dir"/*

run_update() {
    COMMAND_LOG="$command_log" \
    APT_GET_BIN="$stub_dir/apt-get" \
    DKMS_BIN="$stub_dir/dkms" \
    DEPMOD_BIN="$stub_dir/depmod" \
    DPKG_QUERY_BIN="$stub_dir/dpkg-query" \
    SUDO_BIN="$stub_dir/sudo" \
    UNAME_BIN="$stub_dir/uname" \
    MIHOMO_START_BIN="$stub_dir/mihomo-start" \
    VMLINUX_LINK="$test_root/vmlinuz" \
    MODULES_DIR="$modules_dir" \
        "$repo_dir/scripts/update-system.sh" "$@"
}

run_update >"$test_root/proxy.out"

grep -Fqx 'mihomo-start' "$command_log"
grep -Fqx 'sudo -v' "$command_log"
grep -Fq 'apt-get -o Acquire::Retries=3 -o Acquire::http::Proxy=http://127.0.0.1:7890 -o Acquire::https::Proxy=http://127.0.0.1:7890 update' "$command_log"
grep -Fq 'install --no-install-recommends linux-image-amd64 linux-headers-amd64 nvidia-driver' "$command_log"
grep -Fq 'full-upgrade' "$command_log"
grep -Fqx "dkms autoinstall -k $target_kernel" "$command_log"
grep -Fqx "depmod -a $target_kernel" "$command_log"
grep -Fq '系统升级和内核模块检查完成。' "$test_root/proxy.out"
grep -Fq "最新内核：$target_kernel" "$test_root/proxy.out"
grep -Fq '不要执行 apt autoremove' "$test_root/proxy.out"

: >"$command_log"
run_update --direct >"$test_root/direct.out"
if grep -Fq 'mihomo-start' "$command_log"; then
    echo 'direct update unexpectedly started Mihomo' >&2
    exit 1
fi
if grep -Fq 'Acquire::http::Proxy' "$command_log"; then
    echo 'direct update unexpectedly configured an APT proxy' >&2
    exit 1
fi
grep -Fq 'APT 使用直连' "$test_root/direct.out"

printf '%s\n' 'update-system tests passed'
