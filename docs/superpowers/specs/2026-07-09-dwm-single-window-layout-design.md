# DWM Single Window Layout Design

## Goal

When a monitor has exactly one visible tiled client, dwm should:

- remove layout gaps
- remove the blue focus border
- keep the existing multi-window behavior unchanged

## Scope

This change applies only to tiled clients in arranged layouts.

It does not change:

- floating windows
- fullscreen behavior
- multi-window border and gap behavior

## Design

Add two small helpers in `dwm.c`:

- `numtiledvisible(Monitor *m)` counts visible non-floating tiled clients
- `shouldhideborder(Client *c)` decides whether the current client is the only visible tiled client on its monitor

Use the helpers in `tile`, `magicgrid`, and `monocle` so the single tiled window receives:

- zero outer and inner gaps
- zero border width

Use the helper in `focus` so the selected window does not receive the blue focus border when that border should be hidden.

## Why This Design

- `KISS`: the behavior is driven by two small helpers instead of duplicating checks everywhere
- `DRY`: all layouts share the same single-window rule
- `YAGNI`: only the requested behavior changes, without adding new toggles or configuration
