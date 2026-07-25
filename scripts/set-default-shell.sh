#!/usr/bin/env bash
set -euo pipefail

target_user=${TARGET_USER:-${SUDO_USER:-$USER}}
shells_file=${SHELLS_FILE:-/etc/shells}

for required_command in getent zsh sudo; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        printf 'set-default-shell: missing command: %s\n' "$required_command" >&2
        exit 1
    fi
done

zsh_path=$(command -v zsh)
if ! grep -Fqx "$zsh_path" "$shells_file"; then
    printf 'set-default-shell: %s is not listed in %s\n' \
        "$zsh_path" "$shells_file" >&2
    exit 1
fi

passwd_record=$(getent passwd "$target_user")
if [[ -z $passwd_record ]]; then
    printf 'set-default-shell: user not found: %s\n' "$target_user" >&2
    exit 1
fi
current_shell=$(cut -d: -f7 <<<"$passwd_record")

if [[ $current_shell == "$zsh_path" ]]; then
    printf 'set-default-shell: already using %s\n' "$zsh_path"
    exit 0
fi

printf '==> 将 %s 的默认 Shell 切换为 %s\n' "$target_user" "$zsh_path"
sudo chsh -s "$zsh_path" "$target_user"
