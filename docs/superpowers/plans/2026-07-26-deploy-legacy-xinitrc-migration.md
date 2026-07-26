# Legacy `.xinitrc` Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the exact repository-generated legacy `~/.xinitrc` entry to the managed symlink without weakening conflict protection.

**Architecture:** Keep the generic link deployment strict. Add one optional trusted legacy-file path, compare it byte-for-byte before replacement, and use it only for `.xinitrc`.

**Tech Stack:** POSIX shell, Bash integration tests.

## Global Constraints

- Never overwrite an unknown regular file or an incorrect symlink.
- Apply legacy migration only to `.xinitrc`.
- Preserve idempotent deployment.
- Do not commit or push automatically.

---

### Task 1: Add the legacy migration regression test

**Files:**
- Modify: `tests/deploy_test.sh`

**Interfaces:**
- Consumes: `HOME` and `scripts/deploy.sh`.
- Produces: a behavioral test proving the exact legacy entry becomes the managed symlink.

- [ ] **Step 1: Add a temporary HOME containing the exact legacy `.xinitrc` entry**

Run `scripts/deploy.sh` against it and assert `.xinitrc` is a symlink to
`x11/xinitrc`. Keep the existing custom-file rejection assertion.

- [ ] **Step 2: Verify the regression test fails for the expected conflict**

Run: `bash tests/deploy_test.sh`

Expected: FAIL because the current script reports the legacy `.xinitrc` as an existing-file conflict.

### Task 2: Implement narrowly scoped migration

**Files:**
- Create: `x11/xinitrc.legacy`
- Modify: `scripts/deploy.sh`

**Interfaces:**
- Consumes: an optional third `link_config` argument containing a trusted legacy file.
- Produces: byte-for-byte migration of that file before creating the managed symlink.

- [ ] **Step 1: Add the exact historical entry to `x11/xinitrc.legacy`**

```sh
#!/bin/sh

exec "$HOME/workspace/personal/debian-desktop/x11/xinitrc" "$@"
```

- [ ] **Step 2: Add minimal migration logic**

Before treating a regular target as a conflict, use `cmp -s` against the
optional trusted file. On an exact match, remove only that explicit target,
then continue to the existing `ln -s` operation.

- [ ] **Step 3: Pass the legacy file only for `.xinitrc`**

All other `link_config` calls retain their current strict behavior.

- [ ] **Step 4: Verify focused and full tests**

Run:

```bash
sh -n scripts/deploy.sh
bash tests/deploy_test.sh
for test_file in tests/*_test.sh; do bash "$test_file"; done
git diff --check
```

Expected: all commands exit successfully.

### Task 3: Repair and verify the current environment

**Files:**
- Runtime links below `/home/dev`; no repository file changes.

**Interfaces:**
- Consumes: the updated deployment and shell setup scripts.
- Produces: managed configuration links, `.zshrc`, and Zsh as `dev`'s login shell.

- [ ] **Step 1: Run `./scripts/deploy.sh`**

Expected: the known legacy `.xinitrc` migrates and missing configuration links are created.

- [ ] **Step 2: Run `./scripts/set-default-shell.sh`**

Expected: `dev`'s shell changes from `/bin/bash` to `/usr/bin/zsh`.

- [ ] **Step 3: Run health and fresh-shell checks**

Run:

```bash
./scripts/check.sh
zsh -lic 'whence omz >/dev/null'
```

Expected: both commands exit successfully.
