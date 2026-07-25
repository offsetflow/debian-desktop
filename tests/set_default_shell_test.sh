#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

stub_dir="$tmp_dir/bin"
command_log="$tmp_dir/commands.log"
shells_file="$tmp_dir/shells"
mkdir -p "$stub_dir"

cat >"$stub_dir/zsh" <<'EOF'
#!/bin/sh
exit 0
EOF
cat >"$stub_dir/getent" <<'EOF'
#!/bin/sh
printf 'dev:x:1000:1000:Dev User:/home/dev:%s\n' "$CURRENT_SHELL"
EOF
cat >"$stub_dir/sudo" <<'EOF'
#!/bin/sh
printf 'sudo' >>"$COMMAND_LOG"
printf ' %s' "$@" >>"$COMMAND_LOG"
printf '\n' >>"$COMMAND_LOG"
EOF
chmod +x "$stub_dir/zsh" "$stub_dir/getent" "$stub_dir/sudo"
zsh_path="$stub_dir/zsh"
printf '%s\n' "$zsh_path" >"$shells_file"

run_switcher() {
    current_shell=$1
    PATH="$stub_dir:$PATH" \
    USER=dev \
    TARGET_USER=dev \
    CURRENT_SHELL="$current_shell" \
    COMMAND_LOG="$command_log" \
    SHELLS_FILE="$shells_file" \
        "$repo_dir/scripts/set-default-shell.sh"
}

: >"$command_log"
run_switcher "$zsh_path"
[[ ! -s "$command_log" ]]

: >"$command_log"
run_switcher /bin/bash
grep -Fqx "sudo chsh -s $zsh_path dev" "$command_log"

: >"$command_log"
: >"$shells_file"
if run_switcher /bin/bash >"$tmp_dir/missing-shell.out" 2>&1; then
    echo "expected an unregistered Zsh path to fail" >&2
    exit 1
fi
[[ ! -s "$command_log" ]]

printf '%s\n' "set-default-shell tests passed"
