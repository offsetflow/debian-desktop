# Debian Desktop Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide one idempotent `./prepare.sh` command that installs, builds, deploys, and validates the repository-managed Debian dwm desktop.

**Architecture:** A small root orchestrator calls focused scripts for APT dependencies, suckless installation, Picom installation, symlink deployment, and static verification. Shell tests use a temporary HOME and command stubs so they never call APT, sudo, Meson, or write into the real user environment.

**Tech Stack:** POSIX shell, Bash test scripts, APT, Make, Meson/Ninja, Git.

## Global Constraints

- The default flow installs only the base desktop; mise, Docker, mihomo, databases, and development services remain opt-in.
- User-level programs are installed below `~/.local`.
- Configuration is deployed with symlinks to repository files.
- Existing regular files, directories, and incorrect symlinks are never overwritten.
- Scripts derive the repository root from their own path and do not depend on the caller's working directory.
- Tests must not write to the real HOME or invoke APT/sudo.
- Existing unrelated working-tree changes must not be included in this feature's commits.

---

### Task 1: Configuration deployment

**Files:**
- Create: `scripts/deploy.sh`
- Create: `tests/deploy_test.sh`

**Interfaces:**
- Consumes: repository paths resolved relative to `scripts/deploy.sh`; `HOME`.
- Produces: `scripts/deploy.sh`, returning zero when all links are correct and nonzero without overwriting on conflicts.

- [ ] **Step 1: Write the failing deployment test**

Create a temporary HOME, copy only the required repository-shaped fixture files, and assert:

```bash
"$fixture_repo/scripts/deploy.sh"
test "$(readlink "$test_home/.xinitrc")" = "$fixture_repo/x11/xinitrc"
test "$(readlink "$test_home/.config/picom/picom.conf")" = "$fixture_repo/picom/picom.conf"
test "$(readlink "$test_home/.config/polybar/config.ini")" = "$fixture_repo/polybar/config.ini"
test "$(readlink "$test_home/.config/fontconfig/fonts.conf")" = "$fixture_repo/fontconfig/fonts.conf"
"$fixture_repo/scripts/deploy.sh"
printf 'personal config\n' > "$test_home/.xinitrc"
if "$fixture_repo/scripts/deploy.sh"; then
    echo "expected conflict to fail" >&2
    exit 1
fi
test "$(cat "$test_home/.xinitrc")" = "personal config"
```

The test must use `mktemp -d`, install a trap, and never use the real HOME.

- [ ] **Step 2: Run the test and verify failure**

Run: `bash tests/deploy_test.sh`

Expected: FAIL because `scripts/deploy.sh` does not exist.

- [ ] **Step 3: Implement the deployment script**

Use POSIX shell with `set -eu`, resolve the repository using:

```sh
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
```

Implement `link_config source target` with these exact rules:

```sh
if [ -L "$target" ]; then
    [ "$(readlink "$target")" = "$source" ] && return 0
    echo "deploy: conflict: $target is a symlink to $(readlink "$target")" >&2
    return 1
fi
[ ! -e "$target" ] || {
    echo "deploy: conflict: $target already exists" >&2
    return 1
}
mkdir -p "$(dirname "$target")"
ln -s "$source" "$target"
```

Call it for `.xinitrc`, Picom, Polybar, and fontconfig.

- [ ] **Step 4: Run deployment tests and syntax check**

Run:

```bash
sh -n scripts/deploy.sh
bash tests/deploy_test.sh
```

Expected: both commands exit zero.

- [ ] **Step 5: Commit deployment**

```bash
git add scripts/deploy.sh tests/deploy_test.sh
git commit -m "feat: add idempotent desktop config deployment"
```

### Task 2: Base desktop dependency installer

**Files:**
- Create: `scripts/prepare-desktop.sh`
- Create: `tests/prepare_desktop_test.sh`

**Interfaces:**
- Consumes: `sudo` and `apt-get` found through PATH.
- Produces: `scripts/prepare-desktop.sh`, which installs the exact base desktop runtime and build dependency list.

- [ ] **Step 1: Write the failing dependency test**

Place stub `sudo` and `apt-get` commands in a temporary `PATH`. Record arguments and assert:

```bash
PATH="$stub_dir:$PATH" COMMAND_LOG="$command_log" scripts/prepare-desktop.sh
grep -Fqx 'sudo apt-get update' "$command_log"
grep -Fq 'sudo apt-get install --no-install-recommends -y' "$command_log"
grep -Fq 'xserver-xorg-core' "$command_log"
grep -Fq 'libx11-dev' "$command_log"
grep -Fq 'polybar' "$command_log"
grep -Fq 'fcitx5-chinese-addons' "$command_log"
grep -Fq 'pipewire-pulse' "$command_log"
grep -Fq 'fonts-font-awesome' "$command_log"
```

The `sudo` stub must log and then execute its arguments, while the `apt-get`
stub only logs. The test must also assert that `mise`, `docker`, and `mihomo`
do not occur in the install log.

- [ ] **Step 2: Run the test and verify failure**

Run: `bash tests/prepare_desktop_test.sh`

Expected: FAIL because `scripts/prepare-desktop.sh` does not exist.

- [ ] **Step 3: Implement the dependency installer**

Create a Bash script with `set -euo pipefail`, command checks, `sudo apt-get update`,
and one `sudo apt-get install --no-install-recommends -y` invocation. Preserve the
package groups from the approved spec:

```text
X11/runtime: xserver-xorg-core xserver-xorg-input-libinput xinit
             x11-xserver-utils dbus-x11
desktop runtime: polybar fcitx5 fcitx5-chinese-addons pipewire
                 pipewire-pulse wireplumber pavucontrol pamixer feh
fonts: fonts-jetbrains-mono fonts-noto-cjk fonts-font-awesome
build tools: build-essential pkg-config meson ninja-build
suckless headers: libx11-dev libxft-dev libxinerama-dev libxrender-dev
Picom headers: libx11-xcb-dev libxcb1-dev libxcb-composite0-dev
                libxcb-damage0-dev libxcb-glx0-dev libxcb-image0-dev
                libxcb-present-dev libxcb-randr0-dev libxcb-render0-dev
                libxcb-render-util0-dev libxcb-shape0-dev libxcb-util-dev
                libxcb-xfixes0-dev libpixman-1-dev libconfig-dev libegl-dev
                libgl-dev libepoxy-dev libpcre2-dev libev-dev uthash-dev
                libfontconfig1-dev libfreetype-dev
```

Explain each group immediately above its package array. Do not modify the dirty
`scripts/prepare-suckless.sh`; it remains a legacy/upstream preparation utility.

- [ ] **Step 4: Run dependency tests and syntax check**

Run:

```bash
bash -n scripts/prepare-desktop.sh
bash tests/prepare_desktop_test.sh
```

Expected: both commands exit zero.

- [ ] **Step 5: Commit dependency installer**

```bash
git add scripts/prepare-desktop.sh tests/prepare_desktop_test.sh
git commit -m "feat: add base desktop dependency installer"
```

### Task 3: Picom installer

**Files:**
- Create: `scripts/install-picom.sh`
- Create: `tests/install_picom_test.sh`

**Interfaces:**
- Consumes: repository `picom/` source, `meson`, and `HOME`.
- Produces: Picom installed with prefix `$HOME/.local`; accepts `PICOM_BUILD_DIR` for isolated tests/builds.

- [ ] **Step 1: Write the failing Picom installer test**

Stub `meson`, set `PICOM_BUILD_DIR` to a temporary path, run the installer from
outside the repository, and assert the recorded calls are:

```text
meson setup <build-dir> <repo>/picom --prefix <test-home>/.local --buildtype release --reconfigure
meson compile -C <build-dir>
meson install -C <build-dir>
```

The stub must simulate the build directory before the second invocation so
repeated execution follows the same reconfigure path.

- [ ] **Step 2: Run the test and verify failure**

Run: `bash tests/install_picom_test.sh`

Expected: FAIL because `scripts/install-picom.sh` does not exist.

- [ ] **Step 3: Implement Picom installation**

Use Bash with `set -euo pipefail`, resolve the repo relative to the script, and:

```bash
build_dir=${PICOM_BUILD_DIR:-"$repo_dir/picom/build"}
meson setup "$build_dir" "$repo_dir/picom" \
    --prefix "$HOME/.local" \
    --buildtype release \
    --reconfigure
meson compile -C "$build_dir"
meson install -C "$build_dir"
```

Before setup, create the build directory only when necessary and verify
`picom/meson.build` exists.

- [ ] **Step 4: Run Picom installer tests and syntax check**

Run:

```bash
bash -n scripts/install-picom.sh
bash tests/install_picom_test.sh
```

Expected: both commands exit zero.

- [ ] **Step 5: Commit Picom installer**

```bash
git add scripts/install-picom.sh tests/install_picom_test.sh
git commit -m "feat: add repository Picom installer"
```

### Task 4: Installation checker and root orchestrator

**Files:**
- Create: `scripts/check.sh`
- Create: `prepare.sh`
- Create: `tests/check_test.sh`
- Create: `tests/prepare_test.sh`

**Interfaces:**
- Consumes: commands in PATH, `HOME`, repository scripts, and repository-managed link sources.
- Produces: `scripts/check.sh`, returning nonzero after reporting all missing items; `prepare.sh`, calling the five stages in fixed order.

- [ ] **Step 1: Write failing checker tests**

Use a temporary HOME and PATH containing stubs for all required commands. Create
correct configuration links, then assert `scripts/check.sh` succeeds. Remove the
`picom` stub and replace one link with a conflict, then assert it fails and its
output contains both:

```text
missing command: picom
incorrect link:
```

Required commands are `dwm`, `st`, `dmenu`, `picom`, `polybar`, `startx`,
`fcitx5`, `pipewire`, and `wireplumber`.

- [ ] **Step 2: Write the failing orchestrator test**

Copy `prepare.sh` into a temporary repository fixture. Create stubs at the five
expected script paths that append their names to a log, run from `/tmp`, and assert:

```text
prepare-desktop.sh
install-suckless.sh
install-picom.sh
deploy.sh
check.sh
```

Also make `install-picom.sh` fail and assert later stages are not invoked.

- [ ] **Step 3: Run both tests and verify failure**

Run:

```bash
bash tests/check_test.sh
bash tests/prepare_test.sh
```

Expected: FAIL because `scripts/check.sh` and `prepare.sh` do not exist.

- [ ] **Step 4: Implement the checker**

Use POSIX shell and accumulate a numeric `failed` flag instead of exiting at the
first missing item:

```sh
for command_name in dwm st dmenu picom polybar startx fcitx5 pipewire wireplumber; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "check: missing command: $command_name" >&2
        failed=1
    fi
done
```

Check the four exact symlink pairs used by `deploy.sh` and executable permission
on `x11/start-dwm.sh`, `picom/launch.sh`, `polybar/launch.sh`, and
`wallpapers/set-wallpaper.sh`. Exit with `failed`.

- [ ] **Step 5: Implement the root orchestrator**

Use Bash with `set -euo pipefail`, derive `REPO_DIR` from `prepare.sh`, check for
`apt-get`, then execute these exact paths in sequence:

```bash
"$REPO_DIR/scripts/prepare-desktop.sh"
"$REPO_DIR/scripts/install-suckless.sh"
"$REPO_DIR/scripts/install-picom.sh"
"$REPO_DIR/scripts/deploy.sh"
"$REPO_DIR/scripts/check.sh"
```

Print a final message showing `startx`; do not start X automatically.

- [ ] **Step 6: Run checker and orchestrator tests**

Run:

```bash
sh -n scripts/check.sh
bash -n prepare.sh
bash tests/check_test.sh
bash tests/prepare_test.sh
```

Expected: all commands exit zero.

- [ ] **Step 7: Commit orchestration**

```bash
git add prepare.sh scripts/check.sh tests/check_test.sh tests/prepare_test.sh
git commit -m "feat: add one-command desktop bootstrap"
```

### Task 5: End-to-end verification and documentation

**Files:**
- Modify only if verification exposes a bootstrap-specific defect in:
  `prepare.sh`, `scripts/prepare-desktop.sh`, `scripts/install-picom.sh`,
  `scripts/deploy.sh`, `scripts/check.sh`, or their new tests.

**Interfaces:**
- Consumes: all deliverables from Tasks 1–4.
- Produces: verified bootstrap implementation with no unrelated staged files.

- [ ] **Step 1: Run all bootstrap tests**

Run:

```bash
for test_file in \
    tests/deploy_test.sh \
    tests/prepare_desktop_test.sh \
    tests/install_picom_test.sh \
    tests/check_test.sh \
    tests/prepare_test.sh
do
    bash "$test_file"
done
```

Expected: every test exits zero.

- [ ] **Step 2: Run all repository source tests**

Run:

```bash
for test_file in tests/*_test.sh; do
    bash "$test_file"
done
```

Expected: every test exits zero. If an unrelated pre-existing test fails because
of dirty user changes, record it without modifying those files.

- [ ] **Step 3: Compile suckless sources without installing**

Run:

```bash
make -C suckless/dwm clean all
make -C suckless/st clean all
make -C suckless/dmenu clean all
```

Expected: all three builds exit zero.

- [ ] **Step 4: Compile Picom in an isolated temporary directory**

Run:

```bash
picom_verify_dir=$(mktemp -d)
meson setup "$picom_verify_dir/build" picom --prefix "$picom_verify_dir/prefix" --buildtype release
meson compile -C "$picom_verify_dir/build"
```

Expected: configuration and compilation exit zero; remove the temporary directory
afterward.

- [ ] **Step 5: Run final static checks**

Run:

```bash
bash -n prepare.sh scripts/prepare-desktop.sh scripts/install-picom.sh
sh -n scripts/deploy.sh scripts/check.sh
git diff --check
git status --short
git diff --cached --name-only
```

Expected: syntax and whitespace checks pass, and no unrelated files are staged.

- [ ] **Step 6: Commit any verification-only fixes**

If Tasks 1–4 required no follow-up fix, skip this commit. Otherwise:

```bash
git add prepare.sh scripts/prepare-desktop.sh scripts/install-picom.sh \
    scripts/deploy.sh scripts/check.sh tests/deploy_test.sh \
    tests/prepare_desktop_test.sh tests/install_picom_test.sh \
    tests/check_test.sh tests/prepare_test.sh
git commit -m "fix: harden desktop bootstrap verification"
```
