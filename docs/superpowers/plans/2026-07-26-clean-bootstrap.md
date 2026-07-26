# Clean Debian Desktop Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `prepare.sh` a clean, repeatable new-machine bootstrap while removing stale configuration, unused assets, and path inconsistencies.

**Architecture:** Keep one orchestrating script and focused installers beneath `scripts/`. Treat `config.def.h` as the only tracked suckless configuration, install every user binary under `~/.local/bin`, and verify the exact runtime paths with shell tests.

**Tech Stack:** POSIX shell, Bash, Debian APT, Make, Meson, X11, shell-based regression tests.

## Global Constraints

- Do not install Docker or mihomo from `prepare.sh`.
- Do not overwrite conflicting user configuration.
- Do not commit, push, or use destructive Git commands.
- Keep Picom's vendored source tree.
- Keep `x11/xinitrc.legacy` while deployment still uses it for migration.
- Use tests before each behavior change.

---

### Task 1: Unify Picom installation and runtime paths

**Files:**
- Modify: `tests/install_picom_test.sh`
- Modify: `tests/check_test.sh`
- Create: `tests/picom_launch_test.sh`
- Modify: `picom/launch.sh`
- Modify: `scripts/check.sh`

**Interfaces:**
- Consumes: Picom installed by `scripts/install-picom.sh` at `$HOME/.local/bin/picom`.
- Produces: runtime and readiness checks that require that exact executable.

- [ ] **Step 1: Write failing tests**

Add assertions that `picom/launch.sh` invokes `$HOME/.local/bin/picom` and that `check.sh` fails when only an unrelated PATH Picom exists.

- [ ] **Step 2: Verify the tests fail**

Run:

```bash
tests/picom_launch_test.sh
tests/check_test.sh
```

Expected: failure because the launcher uses `/usr/local/bin/picom` and the checker accepts any PATH result.

- [ ] **Step 3: Implement the path contract**

Set:

```sh
PICOM_BIN=${PICOM_BIN:-"$HOME/.local/bin/picom"}
```

in the launcher and check that exact executable in `scripts/check.sh`.

- [ ] **Step 4: Run focused tests**

```bash
tests/picom_launch_test.sh
tests/install_picom_test.sh
tests/check_test.sh
```

Expected: all pass.

### Task 2: Correct DisplayPort monitor classification

**Files:**
- Modify: `tests/setup_monitors_test.sh`
- Modify: `x11/setup-monitors.sh`

**Interfaces:**
- Consumes: connected output names from `xrandr --query`.
- Produces: one internal output and the first non-internal external output.

- [ ] **Step 1: Add failing `eDP-1 + DP-1` coverage**

Assert that `DP-1` becomes the primary external monitor and is positioned relative to `eDP-1`. Retain HDMI and internal-only cases.

- [ ] **Step 2: Verify the DP test fails**

```bash
tests/setup_monitors_test.sh
```

Expected: failure because `DP-1` is classified as internal.

- [ ] **Step 3: Restrict the internal display patterns**

Use:

```sh
eDP*|LVDS*|DSI*)
```

and classify every other connected output as external.

- [ ] **Step 4: Run the monitor tests**

```bash
tests/setup_monitors_test.sh
```

Expected: all topology cases pass.

### Task 3: Make suckless configuration single-source

**Files:**
- Modify: `.gitignore`
- Modify: `suckless/dwm/config.def.h`
- Modify: `suckless/st/config.def.h`
- Delete: `suckless/dwm/config.h`
- Delete: `suckless/st/config.h`
- Delete: `suckless/dmenu/config.h`
- Modify: `scripts/install-suckless.sh`
- Modify: `tests/dwm_dynamic_desktop_names_source_test.sh`
- Modify: `tests/st_alpha_source_test.sh`
- Create: `tests/suckless_config_test.sh`

**Interfaces:**
- Consumes: tracked `suckless/{dwm,st,dmenu}/config.def.h`.
- Produces: generated `config.h` immediately before each clean build.

- [ ] **Step 1: Write a failing single-source test**

Require all custom source assertions to inspect `config.def.h`; require tracked `config.h` files to be absent; exercise an installer run that recreates `config.h`.

- [ ] **Step 2: Verify the test fails**

```bash
tests/suckless_config_test.sh
```

Expected: failure because three `config.h` files are tracked.

- [ ] **Step 3: Reconcile authoritative configurations**

Move the dwm `app_labels` definition and intended st customizations into their respective `config.def.h`. Remove accidental malformed st text rather than preserving it.

- [ ] **Step 4: Generate build configuration explicitly**

Before `make`, run:

```bash
cp "$target/config.def.h" "$target/config.h"
```

Ignore `/suckless/*/config.h` and remove the tracked copies.

- [ ] **Step 5: Run source and installer tests**

```bash
tests/suckless_config_test.sh
tests/dwm_dynamic_desktop_names_source_test.sh
tests/st_alpha_source_test.sh
```

Expected: all pass.

### Task 4: Integrate a clean mise installer into the main bootstrap

**Files:**
- Modify: `tests/prepare_test.sh`
- Create: `tests/prepare_mise_test.sh`
- Modify: `scripts/prepare-mise.sh`
- Modify: `prepare.sh`
- Modify: `scripts/check.sh`
- Modify: `tests/check_test.sh`
- Modify: `docs/mise.md`

**Interfaces:**
- Consumes: `curl`, `HOME`, and optional `MISE_INSTALL_URL`.
- Produces: executable `$HOME/.local/bin/mise` without editing `.profile` or `.bashrc`.

- [ ] **Step 1: Add failing bootstrap and isolation tests**

Require `prepare.sh` to call `prepare-mise.sh` after system dependencies and before builds. Run the mise installer twice against a fake installer and assert that `.profile` and `.bashrc` remain untouched.

- [ ] **Step 2: Verify focused tests fail**

```bash
tests/prepare_mise_test.sh
tests/prepare_test.sh
```

Expected: the old mise script edits Bash files and the main bootstrap omits mise.

- [ ] **Step 3: Reduce `prepare-mise.sh` to one responsibility**

Check for `curl`, create `~/.local/bin` and `~/.config/mise`, install only when the binary is missing, and print its version. Do not activate mise or edit shell startup files.

- [ ] **Step 4: Add mise to `prepare.sh` and checks**

Expand progress to eight steps and require `$HOME/.local/bin/mise` to be executable in `check.sh`.

- [ ] **Step 5: Run focused tests**

```bash
tests/prepare_mise_test.sh
tests/prepare_test.sh
tests/check_test.sh
tests/zshrc_source_test.sh
```

Expected: all pass.

### Task 5: Remove unmanaged Shell and Xresources behavior

**Files:**
- Modify: `tests/zshrc_source_test.sh`
- Modify: `tests/xinitrc_proxy_env_test.sh`
- Modify: `shell/zshrc`
- Modify: `x11/xinitrc`

**Interfaces:**
- Consumes: optional `$HOME/.Xresources`.
- Produces: repository-managed Zsh PATH and conditional Xresources loading.

- [ ] **Step 1: Add failing assertions**

Require no `/home/dev` or OpenCode PATH in `shell/zshrc`; require `xrdb` to run only when `$HOME/.Xresources` is readable and `xrdb` exists.

- [ ] **Step 2: Verify tests fail**

```bash
tests/zshrc_source_test.sh
tests/xinitrc_proxy_env_test.sh
```

Expected: failure on the hard-coded OpenCode path and unconditional `xrdb`.

- [ ] **Step 3: Simplify both entrypoints**

Delete the OpenCode PATH lines. Guard Xresources loading with:

```sh
if [ -r "$HOME/.Xresources" ] && command -v xrdb >/dev/null 2>&1; then
    xrdb -merge "$HOME/.Xresources"
fi
```

- [ ] **Step 4: Run focused tests**

```bash
tests/zshrc_source_test.sh
tests/xinitrc_proxy_env_test.sh
```

Expected: both pass.

### Task 6: Make optional mihomo prerequisites explicit

**Files:**
- Create: `tests/prepare_mihomo_test.sh`
- Modify: `scripts/prepare-mihomo.sh`
- Modify: `docs/mihomo.md`

**Interfaces:**
- Consumes: `curl`, `jq`, `gzip`, and the repository update-profile script.
- Produces: a clear failure listing the first missing command before filesystem or network changes.

- [ ] **Step 1: Add a failing missing-command test**

Run with a constrained PATH and assert:

```text
prepare-mihomo: missing command: jq
```

- [ ] **Step 2: Verify it fails for the wrong reason**

```bash
tests/prepare_mihomo_test.sh
```

Expected: the current script reaches a missing utility without its own diagnostic.

- [ ] **Step 3: Add prerequisite checks and documentation**

Check `curl`, `jq`, `gzip`, `mktemp`, and `head` before creating directories or downloading. Document the Debian packages needed by this optional installer.

- [ ] **Step 4: Run the mihomo test**

```bash
tests/prepare_mihomo_test.sh
```

Expected: pass.

### Task 7: Remove obsolete and unused repository content

**Files:**
- Delete: `scripts/prepare-suckless.sh`
- Delete: `wallpapers/dark-fluid-ultrawide.png`
- Delete: `wallpapers/wallhaven-gw2gyq-1920x1080.png`
- Delete: `wallpapers/wallhaven-xedleo_3000x1687.png`
- Delete: old files in `docs/superpowers/plans/`
- Delete: old files in `docs/superpowers/specs/`
- Keep: `docs/superpowers/plans/2026-07-26-clean-bootstrap.md`
- Keep: `docs/superpowers/specs/2026-07-26-clean-bootstrap-design.md`
- Create: `tests/repository_hygiene_test.sh`

**Interfaces:**
- Consumes: the intended minimal tracked-file inventory.
- Produces: no references to removed scripts or assets.

- [ ] **Step 1: Add a failing hygiene test**

Assert the obsolete script and three unused wallpapers are absent, the active wallpaper remains, and no maintained file references removed paths.

- [ ] **Step 2: Verify it fails**

```bash
tests/repository_hygiene_test.sh
```

Expected: failure while obsolete content exists.

- [ ] **Step 3: Delete the approved files**

Use patch-based deletions for text files and explicit filesystem deletion for the three approved binary targets after confirming their paths.

- [ ] **Step 4: Run the hygiene test**

```bash
tests/repository_hygiene_test.sh
```

Expected: pass.

### Task 8: Full verification and documentation consistency

**Files:**
- Modify as needed: `KEYBINDINGS.md`
- Modify as needed: `docs/SYSTEM-CONVENTIONS.md`
- Modify as needed: `AGENTS.md`
- Modify: `scripts/check.sh`
- Modify: `tests/check_test.sh`

**Interfaces:**
- Consumes: the completed bootstrap and repository layout.
- Produces: documentation that describes the actual supported workflow.

- [ ] **Step 1: Search for stale paths and instructions**

```bash
rg -n 'prepare-suckless|/usr/local/bin/picom|/home/dev/.opencode|dark-fluid|gw2gyq|xedleo' .
```

Expected: no maintained references.

- [ ] **Step 2: Run every repository test**

```bash
for test_file in tests/*_test.sh; do "$test_file"; done
```

Expected: all pass.

- [ ] **Step 3: Run Shell syntax validation**

```bash
for script_file in prepare.sh scripts/*.sh x11/*.sh x11/xinitrc x11/xinitrc.legacy polybar/*.sh picom/launch.sh wallpapers/*.sh mihomo/*.sh; do
    case "$(head -n 1 "$script_file")" in
        *bash) bash -n "$script_file" ;;
        *) sh -n "$script_file" ;;
    esac
done
```

Expected: no output and exit zero.

- [ ] **Step 4: Rebuild all suckless projects**

```bash
for project in dwm st dmenu; do
    cp "suckless/$project/config.def.h" "suckless/$project/config.h"
    make -C "suckless/$project" clean
    make -C "suckless/$project"
done
```

Expected: all three builds succeed.

- [ ] **Step 5: Verify diff integrity**

```bash
git diff --check
git status --short
```

Expected: no whitespace errors; status lists only intended changes and generated build outputs remain ignored.

- [ ] **Step 6: Record the remaining manual validation**

Report that a real dwm session should confirm DP monitor placement, Picom animation, Polybar, fcitx5, audio, wallpaper, and proxy startup. Do not claim those visual/runtime checks were performed automatically.
