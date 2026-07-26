# Mihomo Node Selector Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a tested dmenu/fzf Mihomo node selector backed by the local REST API.

**Architecture:** Force the REST controller onto loopback at Core startup, then keep selection in one shell script that queries Selector groups and performs a validated PUT. Integrate it into dwm through the tracked `config.def.h`.

**Tech Stack:** Bash, curl, jq, dmenu, fzf, Mihomo REST API, shell tests.

## Global Constraints

- Listen only on `127.0.0.1:9090`.
- Do not rewrite subscription YAML when switching nodes.
- Do not add mihomo or jq to the base desktop bootstrap.
- Do not commit or push.

---

### Task 1: Pin the local controller at startup

**Files:**
- Create: `tests/mihomo_start_test.sh`
- Modify: `mihomo/start.sh`

- [ ] Write a test with a fake Mihomo binary that records arguments.
- [ ] Run it and confirm it fails because `-ext-ctl` is absent.
- [ ] Add `MIHOMO_CONTROLLER_ADDRESS`, defaulting to `127.0.0.1:9090`, and pass it with `-ext-ctl`.
- [ ] Run the focused test and confirm it passes.

### Task 2: Implement selection and API validation

**Files:**
- Create: `tests/mihomo_select_test.sh`
- Create: `mihomo/select.sh`

- [ ] Build a fake curl API fixture covering GET and PUT requests.
- [ ] Add failing cases for direct arguments, fzf selection, dmenu selection, cancellation, unavailable API, missing Selector, unknown group, unknown node, URL encoding, and JSON encoding.
- [ ] Run the test and confirm failure because the selector does not exist.
- [ ] Implement argument parsing, command checks, API retrieval, Selector filtering, menu selection, validation, URL/JSON encoding, PUT, and success output.
- [ ] Run the focused test until every behavior passes.

### Task 3: Add dwm and documentation integration

**Files:**
- Create: `tests/mihomo_integration_test.sh`
- Modify: `suckless/dwm/config.def.h`
- Modify: `KEYBINDINGS.md`
- Modify: `docs/mihomo.md`

- [ ] Add a failing source test for the `Alt + Shift + P` binding and documented selector commands.
- [ ] Run it and confirm the binding is missing.
- [ ] Add the command array and key binding to the authoritative dwm configuration.
- [ ] Document interactive and non-interactive switching and runtime-only selection.
- [ ] Run the integration test and dwm source tests.

### Task 4: Full verification

**Files:**
- No production changes expected.

- [ ] Run all `tests/*_test.sh`.
- [ ] Run Bash/POSIX Shell syntax checks.
- [ ] Generate dwm `config.h`, compile dwm, clean build outputs, and remove generated `config.h`.
- [ ] Run `git diff --check`.
- [ ] Inspect `git status --short` and verify only intended changes remain.
- [ ] Record the required live check: start Mihomo, press `Alt + Shift + P`, select a real node, and verify the active selection.
