# Debian + dwm System Conventions

## Goal

This system exists to provide a lightweight, controllable, reproducible development desktop.

The guiding rules are:

- Keep the system simple (`KISS`).
- Install only what is needed now (`YAGNI`).
- Separate responsibilities clearly.
- Put repeatable setup into scripts.

## Scope

`debian-desktop` manages only desktop and OS bootstrap concerns, such as:

- `dwm`, `st`, `dmenu`
- `picom`, `polybar`
- `xinitrc`, monitor startup scripts
- wallpaper and input method integration
- minimal system packages needed to bring the desktop up

It does **not** manage business projects, generic applications, databases, or local services.

## Directory Responsibility

- Desktop and system configuration live in the desktop repo.
- Development projects live under `~/workspace/playground` or other dedicated workspace directories.
- Local infrastructure and services live in their own directory, not in `debian-desktop`.
- Secrets and local credentials live under `~/.config/...` and must not enter Git.

## Config Management

Configurations that need long-term maintenance should be stored in the repo and linked into the real runtime location with symlinks.

Typical targets include:

- `~/.xinitrc`
- `~/.config/...`

This keeps configuration versioned, easy to restore, and easy to migrate after reinstalling the system.

## Package Policy

System-level packages required to bootstrap the desktop should be written into `prepare.sh` style scripts.

That includes only packages that are necessary to:

- start X11 and dwm
- build and install the desktop components
- enable required desktop behavior

Do not add optional tools there unless they are part of the base system experience.

## Development Runtime Policy

Language runtimes and toolchains should be managed with `mise` whenever possible.

Examples:

- Java
- Node.js
- Maven

Prefer project-local version declarations so that multiple projects can coexist without polluting the whole system.

## Change Policy

When adding a new component, first check:

1. Is it needed now?
2. Does it belong to the desktop layer or the project/service layer?
3. Should it be scripted in prepare/setup?
4. Should it be versioned through a repo-managed config plus symlink?

If the answer is unclear, keep the system smaller by default.
