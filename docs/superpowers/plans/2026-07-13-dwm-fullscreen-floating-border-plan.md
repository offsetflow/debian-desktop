# DWM Fullscreen-Like Floating Border Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the border from floating windows that exactly fill the monitor work area, preventing visible border bleed on adjacent monitors.

**Architecture:** Extend the existing `shouldhideborder` decision in `suckless/dwm/dwm.c` with one additional predicate for floating windows that match monitor work-area geometry. Keep the verification at source level with the existing dwm gap test.

**Tech Stack:** dwm C source, shell source tests

## Global Constraints

- Only touch the border-hiding decision in `dwm`.
- Do not change layout behavior, gap behavior, or picom configuration.
- Keep the fix reversible through repo-managed source only.

---

### Task 1: Lock In The Floating-Maximized Border Rule

**Files:**
- Modify: `tests/dwm_gaps_source_test.sh`
- Modify: `suckless/dwm/dwm.c`

**Interfaces:**
- Consumes: existing `shouldhideborder(Client *c)` helper in `dwm.c`
- Produces: a source-level guarantee that floating windows matching monitor work-area geometry also hide borders

- [ ] **Step 1: Write the failing test**

Add these checks to `tests/dwm_gaps_source_test.sh`:

```sh
grep -q "static int isfullscreenlikefloating(Client \\*c);" "$DWM_C"
grep -q "^isfullscreenlikefloating(Client \\*c)" "$DWM_C"
grep -q "c->isfloating && !c->isfullscreen" "$DWM_C"
grep -q "c->x == c->mon->wx" "$DWM_C"
grep -q "c->y == c->mon->wy" "$DWM_C"
grep -q "WIDTH(c) == c->mon->ww" "$DWM_C"
grep -q "HEIGHT(c) == c->mon->wh" "$DWM_C"
grep -q "isfullscreenlikefloating(c)" "$DWM_C"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `sh tests/dwm_gaps_source_test.sh suckless/dwm/dwm.c`
Expected: FAIL because the floating-maximized helper does not exist yet

- [ ] **Step 3: Write minimal implementation**

Add a helper to `suckless/dwm/dwm.c`:

```c
static int
isfullscreenlikefloating(Client *c)
{
	return c && c->isfloating && !c->isfullscreen && c->mon &&
		c->x == c->mon->wx &&
		c->y == c->mon->wy &&
		WIDTH(c) == c->mon->ww &&
		HEIGHT(c) == c->mon->wh;
}
```

Update `shouldhideborder(Client *c)` to return true when either:

- the existing single tiled window rule matches, or
- `isfullscreenlikefloating(c)` matches

- [ ] **Step 4: Run test to verify it passes**

Run: `sh tests/dwm_gaps_source_test.sh suckless/dwm/dwm.c`
Expected: PASS

- [ ] **Step 5: Verify related dwm source tests still pass**

Run:

```bash
sh tests/dwm_source_test.sh suckless/dwm/dwm.c
sh tests/dwm_magicgrid_source_test.sh suckless/dwm/dwm.c
```

Expected: both PASS

- [ ] **Step 6: Build dwm**

Run:

```bash
cd suckless/dwm && make
```

Expected: build succeeds with exit code 0
