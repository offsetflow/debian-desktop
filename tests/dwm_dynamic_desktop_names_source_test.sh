#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
dwm_c="$repo_root/suckless/dwm/dwm.c"
config_h="$repo_root/suckless/dwm/config.h"

fail() {
    printf '%s\n' "FAIL: $*" >&2
    exit 1
}

grep -Fq 'typedef struct AppLabel AppLabel;' "$dwm_c"     || fail "missing AppLabel declaration"
grep -Fq 'static void getclientlabel(Client *c, char *label, size_t size);' "$dwm_c"     || fail "missing getclientlabel declaration"
grep -Fq 'getclientlabel(Client *c, char *label, size_t size)' "$dwm_c"     || fail "missing getclientlabel implementation"
grep -Fq 'static const AppLabel app_labels[]' "$config_h"     || fail "missing app label mapping"
grep -Fq '{ "St", "   Terminal  " }' "$config_h"     || fail "missing padded terminal label"
grep -Fq '{ "Google-chrome", "   Chrome  " }' "$config_h"     || fail "missing padded Chrome label"
grep -Fq '{ "jetbrains-idea", "   IntelliJ IDEA  " }' "$config_h"     || fail "missing padded IntelliJ IDEA label"
grep -Fq 'char desktopnames[desktops][DESKTOPNAMELEN];' "$dwm_c"     || fail "desktop names should use bounded per-desktop buffers"
grep -Fq 'for (c = m->stack; c; c = c->snext)' "$dwm_c"     || fail "desktop labels should follow focus-stack order"
grep -Fq 'if (c->tags & (1U << tag))' "$dwm_c"     || fail "desktop labels should select clients by tag"
grep -Fq 'memset(desktopnames, 0, sizeof desktopnames);' "$dwm_c"     || fail "empty tags should start with empty names"
grep -Fq 'snprintf(desktopnames[desktop], DESKTOPNAMELEN, "\xE2\x80\x8B");' "$dwm_c" \
    || fail "empty tags should use a zero-width EWMH name instead of Polybar numeric fallback"

focus_body="$(sed -n '/^focus(Client \*c)/,/^}/p' "$dwm_c")"
printf '%s\n' "$focus_body" | grep -Fq 'setdesktopnames();'     || fail "focus changes should refresh desktop names"

printf '%s\n' "OK: dwm publishes dynamic occupied-tag labels"
