# Dynamic Polybar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the approved compact Polybar whose left side shows only occupied dwm tags as app icon/name labels and whose right side provides working desktop controls.

**Architecture:** dwm publishes dynamic `_NET_DESKTOP_NAMES` from its own monitor/tag/client state. Polybar remains the renderer and click target; three focused shell helpers provide brightness, fcitx5, and power actions without adding a daemon.

**Tech Stack:** C99, Xlib/EWMH, Polybar 3.7.2, POSIX shell, xrandr, fcitx5, PipeWire Pulse compatibility, dmenu.

## Global Constraints

- Preserve the existing dwm + Anybar + Polybar architecture.
- Hide empty tags completely.
- Keep nine independent tags per monitor.
- Only the primary monitor owns the X11 tray.
- Do not add a launcher, music module, desktop environment, Eww, or polling daemon.
- Preserve all unrelated uncommitted files.
- Use the current Unicode-capable fonts; do not add an icon font dependency.

---

### Task 1: Dynamic dwm desktop labels

**Files:**
- Modify: `suckless/dwm/dwm.c`
- Modify: `suckless/dwm/config.h`
- Create: `tests/dwm_dynamic_desktop_names_source_test.sh`

**Interfaces:**
- Consumes: dwm `Monitor.stack`, `Client.tags`, `XGetClassHint`, and the existing `setdesktopnames()` EWMH path.
- Produces: `getclientlabel(Client *, char *, size_t)` and dynamic `_NET_DESKTOP_NAMES`.

- [ ] **Step 1: Write the failing source contract**

Create a shell test that requires the `AppLabel` mapping, `getclientlabel`, focus-stack selection, empty-name initialization, and refresh from `focus()`.

- [ ] **Step 2: Run the test and verify RED**

Run:

```bash
sh tests/dwm_dynamic_desktop_names_source_test.sh
```

Expected: failure because `AppLabel` and `getclientlabel` do not exist.

- [ ] **Step 3: Add the minimal mapping and label generator**

Define:

```c
typedef struct {
    const char *class;
    const char *label;
} AppLabel;
```

Add explicit mappings in `config.h` for St, Chrome/Chromium, Firefox, IntelliJ IDEA, VS Code, file managers, and a generic fallback. Implement `getclientlabel` with case-insensitive class matching and bounded `snprintf`.

- [ ] **Step 4: Make desktop names dynamic**

Replace static numeric names with one bounded string per monitor/tag. Walk `Monitor.stack`, select the first client whose tag mask contains the tag, and leave the string empty when no client matches. Call `setdesktopnames()` after `selmon->sel` changes in `focus()`.

- [ ] **Step 5: Verify GREEN and compile**

Run:

```bash
sh tests/dwm_dynamic_desktop_names_source_test.sh
sh tests/dwm_source_test.sh suckless/dwm/dwm.c
sh tests/dwm_gaps_source_test.sh suckless/dwm/dwm.c
make -C suckless/dwm
```

Expected: all commands exit 0.

### Task 2: Focused desktop action helpers

**Files:**
- Create: `polybar/brightness.sh`
- Create: `polybar/input-method.sh`
- Create: `polybar/power-menu.sh`
- Create: `tests/polybar_helpers_test.sh`

**Interfaces:**
- `brightness.sh get|up|down` reads `MONITOR` and prints `☀ NN%` for `get`.
- `input-method.sh status|toggle` prints `EN`, `中`, or `--` for `status`.
- `power-menu.sh` shows one dmenu and executes exactly one selected action.

- [ ] **Step 1: Write failing helper tests**

Use temporary fake `xrandr` and `fcitx5-remote` binaries to verify brightness parsing/clamping and input-method labels. Use `sh -n` for the power menu and assert its four explicit actions.

- [ ] **Step 2: Run the helper test and verify RED**

Run:

```bash
sh tests/polybar_helpers_test.sh
```

Expected: failure because the three helper scripts do not exist.

- [ ] **Step 3: Implement brightness and input helpers**

Use POSIX shell, command overrides `XRANDR_BIN` and `FCITX_REMOTE_BIN` for deterministic tests, bounded values, and quiet failure handling.

- [ ] **Step 4: Implement the power menu**

Pipe the four fixed choices into dmenu. Map them to `systemctl suspend`, `pkill -TERM -x dwm`, `systemctl reboot`, and `systemctl poweroff`; an empty selection exits without action.

- [ ] **Step 5: Verify GREEN**

Run:

```bash
sh tests/polybar_helpers_test.sh
sh -n polybar/brightness.sh polybar/input-method.sh polybar/power-menu.sh
```

Expected: exit 0 with helper test success output.

### Task 3: Polybar layout, tray ownership, and bootstrap

**Files:**
- Modify: `polybar/config.ini`
- Modify: `polybar/launch.sh`
- Modify: `scripts/prepare-suckless.sh`
- Create: `tests/polybar_reference_style_source_test.sh`

**Interfaces:**
- Consumes: dynamic EWMH names from Task 1 and helper commands from Task 2.
- Produces: `POLYBAR_RIGHT_MODULES` per monitor and one primary-monitor tray.

- [ ] **Step 1: Write the failing Polybar contract**

Assert the approved module order, blank dynamic empty labels, red active label, centered date, internal tray, helper command wiring, and environment-driven right module list.

- [ ] **Step 2: Run the test and verify RED**

Run:

```bash
sh tests/polybar_reference_style_source_test.sh
```

Expected: failure because the approved modules and environment-driven module list are absent.

- [ ] **Step 3: Implement the visual configuration**

Set a 28px translucent deep-blue bar, compact padding, system marker, dynamic workspaces, centered date, and the right-side modules. Remove `xwindow` and do not add launcher or music modules.

- [ ] **Step 4: Make tray ownership deterministic**

Parse each `polybar --list-monitors` line. Set `POLYBAR_RIGHT_MODULES` with `tray` only for the line containing `(primary)`; launch all other monitors without tray.

- [ ] **Step 5: Record required packages**

Keep Polybar, PipeWire, pavucontrol and pamixer in `prepare-suckless.sh`. Document that brightness uses existing xrandr and icons use existing Unicode fonts, so no package is added.

- [ ] **Step 6: Verify GREEN and existing multi-monitor contracts**

Run:

```bash
sh tests/polybar_reference_style_source_test.sh
sh tests/polybar_workspace_source_test.sh
sh tests/polybar_per_monitor_workspace_source_test.sh
sh -n polybar/launch.sh
```

Expected: all commands exit 0.

### Task 4: Install and live verification

**Files:**
- Update installed binary: `/home/dev/.local/bin/dwm`
- Runtime logs: `/home/dev/.cache/polybar/*.log`

**Interfaces:**
- Consumes: compiled dwm and committed repository configuration.
- Produces: the live approved bar on both displays.

- [ ] **Step 1: Run the complete targeted verification**

Run all new tests, existing relevant tests, shell syntax checks, and `make -C suckless/dwm`.

- [ ] **Step 2: Install dwm atomically**

Install to `/home/dev/.local/bin/dwm.new`, then rename over `/home/dev/.local/bin/dwm`, and verify with `cmp`.

- [ ] **Step 3: Reload Polybar**

Run `polybar/launch.sh`, then confirm exactly two Polybar processes and no errors in each monitor log.

- [ ] **Step 4: Restart dwm and verify EWMH labels**

After the X session restarts, open Terminal, Chrome, and IntelliJ IDEA on separate tags. Run:

```bash
xprop -root _NET_DESKTOP_NAMES
```

Expected: occupied tags contain mapped app labels; empty tags contain empty strings.

- [ ] **Step 5: Verify interactions**

Click an occupied app label, toggle fcitx5, scroll brightness and volume, open the power menu and cancel it, and confirm only the primary monitor contains the tray.

