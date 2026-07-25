# DWM Fullscreen-Like Floating Border Design

## Goal

Hide the border for a floating window when it fully occupies the monitor work area, so browser windows that behave like maximized floating clients do not bleed a visible border into the neighboring monitor.

## Scope

This change only affects the border-hiding decision in `dwm`.

It does not change:

- layout selection
- gap behavior
- picom shadow or blur rules
- polybar geometry

## Design

Keep the existing "single tiled window hides border" behavior.

Extend the same helper logic so a client also hides its border when all of the following are true:

- it is floating
- it is not fullscreen
- its geometry exactly matches the monitor work area

This treats a "maximized floating window" as a borderless immersive state, which matches user expectation and fixes cross-monitor border bleed without changing layout semantics.

## Why This Design

- `KISS`: one focused rule in `dwm`, no compositor workaround
- `YAGNI`: only fix the real symptom source, the X11 border
- `DRY`: reuse the existing border decision point instead of adding special cases elsewhere
