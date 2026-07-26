#!/usr/bin/env bash
set -euo pipefail

source_repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

fixture_repo="$tmp_dir/repo"
stub_dir="$tmp_dir/bin"
command_log="$tmp_dir/stages.log"
mkdir -p "$fixture_repo/scripts" "$stub_dir"
cp "$source_repo/prepare.sh" "$fixture_repo/prepare.sh"

printf '#!/bin/sh\nexit 0\n' >"$stub_dir/apt-get"
chmod +x "$stub_dir/apt-get"

create_stage() {
    stage_name=$1
    cat >"$fixture_repo/scripts/$stage_name" <<'EOF'
#!/bin/sh
printf '%s\n' "${0##*/}" >>"$STAGE_LOG"
if [ "${FAIL_STAGE:-}" = "${0##*/}" ]; then
    exit 23
fi
EOF
    chmod +x "$fixture_repo/scripts/$stage_name"
}

for stage_name in \
    prepare-desktop.sh \
    install-suckless.sh \
    install-picom.sh \
    install-omz.sh \
    deploy.sh \
    set-default-shell.sh \
    check.sh
do
    create_stage "$stage_name"
done

(
    cd "$tmp_dir"
    PATH="$stub_dir:$PATH" STAGE_LOG="$command_log" "$fixture_repo/prepare.sh"
)

cat >"$tmp_dir/expected.log" <<'EOF'
prepare-desktop.sh
install-suckless.sh
install-picom.sh
install-omz.sh
deploy.sh
set-default-shell.sh
check.sh
EOF
diff -u "$tmp_dir/expected.log" "$command_log"

: >"$command_log"
if PATH="$stub_dir:$PATH" STAGE_LOG="$command_log" FAIL_STAGE=install-omz.sh \
    "$fixture_repo/prepare.sh" >"$tmp_dir/prepare.out" 2>&1
then
    echo "expected a failed stage to stop prepare.sh" >&2
    exit 1
fi

cat >"$tmp_dir/expected-failure.log" <<'EOF'
prepare-desktop.sh
install-suckless.sh
install-picom.sh
install-omz.sh
EOF
diff -u "$tmp_dir/expected-failure.log" "$command_log"

printf '%s\n' "prepare tests passed"
