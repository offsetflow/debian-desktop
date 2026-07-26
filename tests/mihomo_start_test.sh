#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

test_home="$tmp_dir/home"
config_dir="$test_home/.config/mihomo"
stub_dir="$tmp_dir/bin"
args_log="$tmp_dir/args.log"
mkdir -p "$config_dir" "$stub_dir"
printf '%s\n' 'mixed-port: 7890' >"$config_dir/config.yaml"

cat >"$stub_dir/mihomo" <<'EOF'
#!/bin/sh
exit 0
EOF
cat >"$stub_dir/pgrep" <<'EOF'
#!/bin/sh
exit 1
EOF
cat >"$stub_dir/nohup" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >"$ARGS_LOG"
EOF
chmod +x "$stub_dir/mihomo" "$stub_dir/pgrep" "$stub_dir/nohup"

HOME="$test_home" \
PATH="$stub_dir:/usr/bin:/bin" \
ARGS_LOG="$args_log" \
MIHOMO_BIN="$stub_dir/mihomo" \
MIHOMO_CONFIG_DIR="$config_dir" \
    "$repo_dir/mihomo/start.sh" >/dev/null

for _ in {1..20}; do
    [[ -s "$args_log" ]] && break
    sleep 0.01
done

grep -Fq -- '-ext-ctl 127.0.0.1:9090' "$args_log"
grep -Fq -- '-secret ' "$args_log"
grep -Fq -- "-d $config_dir -f $config_dir/config.yaml" "$args_log"

printf '%s\n' "mihomo start tests passed"
