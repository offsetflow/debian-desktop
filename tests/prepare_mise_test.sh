#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

test_home="$tmp_dir/home"
stub_dir="$tmp_dir/bin"
curl_log="$tmp_dir/curl.log"
mkdir -p "$test_home" "$stub_dir"
printf '%s\n' "existing profile" >"$test_home/.profile"
printf '%s\n' "existing bashrc" >"$test_home/.bashrc"

cat >"$stub_dir/curl" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$CURL_LOG"
cat <<'INSTALLER'
#!/bin/sh
cat >"$MISE_INSTALL_PATH" <<'MISE'
#!/bin/sh
printf '%s\n' "mise test-version"
MISE
chmod +x "$MISE_INSTALL_PATH"
INSTALLER
EOF
chmod +x "$stub_dir/curl"

run_installer() {
    HOME="$test_home" \
    PATH="$stub_dir:/usr/bin:/bin" \
    CURL_LOG="$curl_log" \
    MISE_INSTALL_URL="https://example.invalid/install.sh" \
        "$repo_dir/scripts/prepare-mise.sh"
}

run_installer
run_installer

[[ -x "$test_home/.local/bin/mise" ]]
[[ -d "$test_home/.config/mise" ]]
[[ $(<"$test_home/.profile") == "existing profile" ]]
[[ $(<"$test_home/.bashrc") == "existing bashrc" ]]
[[ $(wc -l <"$curl_log") -eq 1 ]]
grep -Fqx -- '-fsSL https://example.invalid/install.sh' "$curl_log"

printf '%s\n' "prepare-mise tests passed"
