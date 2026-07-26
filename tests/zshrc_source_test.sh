#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
zshrc="$repo_dir/shell/zshrc"
version_file="$repo_dir/shell/omz-version"

grep -Fq 'export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"' "$zshrc"
grep -Fq 'export _OMZ_APPLY_PREEXEC_HOOK=false' "$zshrc"
grep -Fq 'export _OMZ_APPLY_CHPWD_HOOK=false' "$zshrc"
grep -Fq 'export _OMZ_APPLY_HISTORYBYFZF=true' "$zshrc"
grep -Fq '$HOME/.local/share/omz/omz.zsh' "$zshrc"
grep -Fq '"$HOME/.local/bin/mise" activate zsh' "$zshrc"

expected_version=3a2df05e6bff546da0d252290bbba333475ad4a0
[[ $(wc -l <"$version_file") -eq 1 ]]
[[ $(<"$version_file") == "$expected_version" ]]

printf '%s\n' "zshrc source tests passed"
