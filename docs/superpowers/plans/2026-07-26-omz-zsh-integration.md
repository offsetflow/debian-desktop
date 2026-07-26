# OMZ Zsh Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install a pinned OMZ checkout, deploy a repository-managed Zsh configuration, and make Zsh the reproducible default shell through the existing one-command desktop bootstrap.

**Architecture:** Keep third-party OMZ source in `~/.local/share/omz`, while this repository owns the pinned commit, `.zshrc`, installer, shell switcher, deployment, and health checks. Extend the existing staged `prepare.sh` flow and use temporary HOME directories plus command/Git fixtures for tests.

**Tech Stack:** Bash, POSIX shell, Zsh, Git, APT, existing shell test suite.

## Global Constraints

- Pin OMZ to `3a2df05e6bff546da0d252290bbba333475ad4a0`.
- Install OMZ below `~/.local/share/omz`; do not vendor or submodule its source.
- Manage `.zshrc` from `shell/zshrc` through a symlink.
- Enable fzf history; disable preexec-title and last-directory hooks.
- Preserve `~/.local/bin`, mise shims, and mise Zsh activation.
- Never overwrite an existing `.zshrc`, OMZ directory of unknown origin, or conflicting `fd`.
- Tests must not access the network, invoke APT/sudo/chsh, or modify the real HOME.
- Do not install optional `bat`, `exa`/`eza`, or `ueberzugpp`.

---

### Task 1: Repository-managed Zsh configuration

**Files:**
- Create: `shell/zshrc`
- Create: `shell/omz-version`
- Modify: `scripts/deploy.sh`
- Modify: `tests/deploy_test.sh`
- Create: `tests/zshrc_source_test.sh`

**Interfaces:**
- Consumes: `HOME`, optional `$HOME/.local/bin/mise`, and `$HOME/.local/share/omz/omz.zsh`.
- Produces: pinned-version file and `.zshrc` symlink with safe OMZ/mise initialization.

- [ ] **Step 1: Extend the deployment test before production changes**

Add this assertion after the first deployment:

```bash
assert_link "$test_home/.zshrc" "$repo_dir/shell/zshrc"
```

After replacing `.xinitrc` with a conflict, also create a separate HOME whose
`.zshrc` is a regular file and assert `deploy.sh` fails without overwriting it.

- [ ] **Step 2: Add a failing Zsh source contract test**

Create `tests/zshrc_source_test.sh` with source assertions:

```bash
grep -Fq 'export _OMZ_APPLY_PREEXEC_HOOK=false' shell/zshrc
grep -Fq 'export _OMZ_APPLY_CHPWD_HOOK=false' shell/zshrc
grep -Fq 'export _OMZ_APPLY_HISTORYBYFZF=true' shell/zshrc
grep -Fq '$HOME/.local/share/omz/omz.zsh' shell/zshrc
grep -Fq '$HOME/.local/share/mise/shims' shell/zshrc
grep -Fq 'mise" activate zsh' shell/zshrc
```

Assert `shell/omz-version` contains exactly:

```text
3a2df05e6bff546da0d252290bbba333475ad4a0
```

- [ ] **Step 3: Run tests and verify RED**

Run:

```bash
bash tests/deploy_test.sh
bash tests/zshrc_source_test.sh
```

Expected: both fail because the new repository files and link do not exist.

- [ ] **Step 4: Implement the minimum configuration**

Create `shell/zshrc` that:

```zsh
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
export _OMZ_APPLY_PREEXEC_HOOK=false
export _OMZ_APPLY_CHPWD_HOOK=false
export _OMZ_APPLY_HISTORYBYFZF=true

if [[ -r "$HOME/.local/share/omz/omz.zsh" ]]; then
    source "$HOME/.local/share/omz/omz.zsh"
else
    print -u2 "zshrc: OMZ is missing; run ~/workspace/personal/debian-desktop/prepare.sh"
fi

if [[ -x "$HOME/.local/bin/mise" ]]; then
    eval "$("$HOME/.local/bin/mise" activate zsh)"
fi
```

Add the exact commit to `shell/omz-version`, extend `deploy.sh` with:

```sh
link_config "$REPO_DIR/shell/zshrc" "$HOME/.zshrc"
```

- [ ] **Step 5: Run GREEN checks**

Run:

```bash
sh -n scripts/deploy.sh
bash tests/deploy_test.sh
bash tests/zshrc_source_test.sh
git diff --check
```

Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add shell/zshrc shell/omz-version scripts/deploy.sh \
    tests/deploy_test.sh tests/zshrc_source_test.sh
git commit -m "feat: add repository-managed Zsh configuration"
```

### Task 2: Pinned OMZ installer

**Files:**
- Create: `scripts/install-omz.sh`
- Create: `tests/install_omz_test.sh`

**Interfaces:**
- Consumes: `shell/omz-version`, `HOME`, `git`, and `fdfind`.
- Produces: detached checkout at `$HOME/.local/share/omz` and correct `$HOME/.local/bin/fd` symlink.

- [ ] **Step 1: Write the failing installer test**

Build a local bare Git fixture with two commits and replace the repository version
file inside a copied fixture repo with the first commit. Set `OMZ_REPOSITORY` to
the local bare path, run the installer twice, and assert:

```bash
test "$(git -C "$test_home/.local/share/omz" rev-parse HEAD)" = "$pinned_commit"
test "$(git -C "$test_home/.local/share/omz" symbolic-ref -q HEAD || true)" = ""
test "$(readlink "$test_home/.local/bin/fd")" = "$stub_dir/fdfind"
```

Also assert an existing non-Git OMZ directory fails without deletion, and a
regular `~/.local/bin/fd` fails without overwrite.

- [ ] **Step 2: Run the test and verify RED**

Run: `bash tests/install_omz_test.sh`

Expected: fail because `scripts/install-omz.sh` does not exist.

- [ ] **Step 3: Implement the pinned installer**

Use Bash with `set -euo pipefail`. Support `OMZ_REPOSITORY` for local tests and
default it to `https://github.com/yaocccc/omz.git`. Validate the version with:

```bash
[[ $version =~ ^[0-9a-f]{40}$ ]] || exit 1
```

For a missing target:

```bash
git clone --no-checkout "$omz_repository" "$omz_dir"
```

For an existing checkout, require:

```bash
git -C "$omz_dir" rev-parse --is-inside-work-tree
git -C "$omz_dir" remote get-url origin
```

to match the configured repository. Then:

```bash
git -C "$omz_dir" fetch --depth 1 origin "$version"
git -C "$omz_dir" checkout --detach "$version"
test "$(git -C "$omz_dir" rev-parse HEAD)" = "$version"
```

Resolve `fdfind` with `command -v`, and create the `fd` link using the same
conflict policy as deployment.

- [ ] **Step 4: Run GREEN checks**

Run:

```bash
bash -n scripts/install-omz.sh
bash tests/install_omz_test.sh
git diff --check
```

Expected: all pass with no network access.

- [ ] **Step 5: Commit**

```bash
git add scripts/install-omz.sh tests/install_omz_test.sh
git commit -m "feat: install pinned OMZ release"
```

### Task 3: Default-shell switcher

**Files:**
- Create: `scripts/set-default-shell.sh`
- Create: `tests/set_default_shell_test.sh`

**Interfaces:**
- Consumes: `getent`, `zsh`, `sudo`, `chsh`, `USER`, and `SHELLS_FILE` override for tests.
- Produces: current user login shell set to the resolved Zsh path.

- [ ] **Step 1: Write the failing shell-switch test**

Create command stubs and assert:

- a passwd record ending in the resolved Zsh path produces no sudo call;
- a passwd record ending in `/bin/bash` records:

```text
sudo chsh -s <stub-zsh-path> dev
```

- a Zsh path absent from the test `SHELLS_FILE` fails without calling chsh.

- [ ] **Step 2: Run test and verify RED**

Run: `bash tests/set_default_shell_test.sh`

Expected: fail because the switcher does not exist.

- [ ] **Step 3: Implement the switcher**

Use Bash with `set -euo pipefail`, resolve:

```bash
target_user=${TARGET_USER:-${SUDO_USER:-$USER}}
zsh_path=$(command -v zsh)
shells_file=${SHELLS_FILE:-/etc/shells}
current_shell=$(getent passwd "$target_user" | cut -d: -f7)
```

Require an exact line match for `zsh_path` in `shells_file`, skip if already
current, otherwise run:

```bash
sudo chsh -s "$zsh_path" "$target_user"
```

- [ ] **Step 4: Run GREEN checks**

Run:

```bash
bash -n scripts/set-default-shell.sh
bash tests/set_default_shell_test.sh
git diff --check
```

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/set-default-shell.sh tests/set_default_shell_test.sh
git commit -m "feat: configure Zsh as the default shell"
```

### Task 4: Bootstrap dependencies, orchestration, and health checks

**Files:**
- Modify: `scripts/prepare-desktop.sh`
- Modify: `scripts/check.sh`
- Modify: `prepare.sh`
- Modify: `tests/prepare_desktop_test.sh`
- Modify: `tests/check_test.sh`
- Modify: `tests/prepare_test.sh`

**Interfaces:**
- Consumes: Tasks 1–3 scripts and configuration.
- Produces: seven-stage one-command bootstrap and static OMZ/Zsh validation.

- [ ] **Step 1: Extend dependency test**

Require `zsh`, `fzf`, `fd-find`, and `lua5.4` in the APT command log.
Run `bash tests/prepare_desktop_test.sh` and expect failure.

- [ ] **Step 2: Extend orchestration test**

Change the expected stage sequence to:

```text
prepare-desktop.sh
install-suckless.sh
install-picom.sh
install-omz.sh
deploy.sh
set-default-shell.sh
check.sh
```

Move the failure injection to `install-omz.sh` and assert later stages do not run.
Run `bash tests/prepare_test.sh` and expect failure.

- [ ] **Step 3: Extend checker test**

Add `zsh`, `fzf`, `fd`, and `lua` stubs; construct a local OMZ Git checkout at
the version in `shell/omz-version`; add `.zshrc` and `fd` links; stub `getent`
with a Zsh passwd record. Assert success, then drift OMZ HEAD and return Bash
from `getent`; assert the checker reports both:

```text
check: OMZ version mismatch:
check: default shell is not Zsh:
```

Run `bash tests/check_test.sh` and expect failure before production changes.

- [ ] **Step 4: Add dependencies**

Add these to the desktop runtime package array:

```bash
zsh
fzf
fd-find
lua5.4
```

- [ ] **Step 5: Extend root orchestration**

Update progress labels to `1/7` through `7/7` and insert:

```bash
"$repo_dir/scripts/install-omz.sh"
"$repo_dir/scripts/deploy.sh"
"$repo_dir/scripts/set-default-shell.sh"
```

before the final checker.

- [ ] **Step 6: Extend checker**

Add `zsh`, `fzf`, `fd`, and `lua` to required commands; check `.zshrc`, OMZ
origin/HEAD, fd target, and passwd shell. Use `ZSH_PATH`, `GETENT_BIN`, and
`OMZ_REPOSITORY` overrides only where needed to keep the checker test isolated.

- [ ] **Step 7: Run GREEN checks**

Run:

```bash
bash tests/prepare_desktop_test.sh
bash tests/prepare_test.sh
bash tests/check_test.sh
bash -n prepare.sh scripts/prepare-desktop.sh
sh -n scripts/check.sh
git diff --check
```

Expected: all pass.

- [ ] **Step 8: Commit**

```bash
git add prepare.sh scripts/prepare-desktop.sh scripts/check.sh \
    tests/prepare_desktop_test.sh tests/prepare_test.sh tests/check_test.sh
git commit -m "feat: integrate OMZ into desktop bootstrap"
```

### Task 5: Full verification

**Files:**
- Modify only OMZ/Zsh integration files if verification exposes a defect.

**Interfaces:**
- Consumes: all previous task outputs.
- Produces: clean, committed feature with fresh verification evidence.

- [ ] **Step 1: Confirm Debian package names**

Run:

```bash
apt-cache show zsh fzf fd-find lua5.4 >/dev/null
```

Expected: exit zero.

- [ ] **Step 2: Run every test**

Run:

```bash
for test_file in tests/*_test.sh; do
    bash "$test_file"
done
```

Expected: all tests pass.

- [ ] **Step 3: Run Shell syntax checks**

Run:

```bash
bash -n prepare.sh scripts/prepare-desktop.sh scripts/install-picom.sh \
    scripts/install-omz.sh scripts/set-default-shell.sh
sh -n scripts/deploy.sh scripts/check.sh
```

If Zsh is locally installed, also run:

```bash
zsh -n shell/zshrc
```

- [ ] **Step 4: Run existing source builds**

Run:

```bash
make -C suckless/dwm clean all
make -C suckless/st clean all
make -C suckless/dmenu clean all
```

Expected: all pass.

- [ ] **Step 5: Inspect final state**

Run:

```bash
git diff --check
git status --short
git log --oneline -8
```

Expected: no unstaged integration files and no unrelated changes.

- [ ] **Step 6: Commit verification fixes only if needed**

If verification required changes, stage only the OMZ/Zsh files and commit:

```bash
git commit -m "fix: harden OMZ Zsh bootstrap"
```
