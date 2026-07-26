#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
dmenu_dir="$repo_dir/suckless/dmenu"
dmenu_config="$dmenu_dir/config.def.h"
dmenu_source="$dmenu_dir/dmenu.c"
dmenu_drw="$dmenu_dir/drw.c"
dwm_config="$repo_dir/suckless/dwm/config.def.h"
picom_config="$repo_dir/picom/picom.conf"

grep -Fq 'static int centered = 1;' "$dmenu_config"
grep -Fq 'static int fuzzy = 1;' "$dmenu_config"
grep -Fq 'static const unsigned int alpha = 0xa0;' "$dmenu_config"
grep -Fq '[SchemeSel]           = { OPAQUE, 0xbc }' "$dmenu_config"
grep -Fq '[SchemeInput]         = { OPAQUE, 0xb0 }' "$dmenu_config"
grep -Fq 'static const unsigned int menu_width = 680;' "$dmenu_config"
grep -Fq 'static unsigned int lines      = 8;' "$dmenu_config"
grep -Fq 'static unsigned int lineheight = 34;' "$dmenu_config"
grep -Fq 'static unsigned int border_width = 1;' "$dmenu_config"
grep -Fq '[SchemeNorm]          = { "#dce7eb", "#1d3040" }' "$dmenu_config"
grep -Fq '[SchemeSel]           = { "#edf7f8", "#0e6070" }' "$dmenu_config"
grep -Fq '[SchemeInput]         = { "#edf4f6", "#405661" }' "$dmenu_config"

grep -Fq 'static void' "$dmenu_source"
grep -Fq 'fuzzymatch(void)' "$dmenu_source"
grep -Fq 'drawhighlights(struct item *item' "$dmenu_source"
grep -Fq 'recalculatenumbers(void)' "$dmenu_source"
grep -Fq 'XRenderFindVisualFormat' "$dmenu_source"
grep -Fq 'drw->visual, drw->cmap' "$dmenu_drw"
grep -Fq -- '-lXrender -lm' "$dmenu_dir/config.mk"

grep -Fq '"dmenu_run", "-i", "-m", dmenumon' "$dwm_config"
grep -Fq '"-p", "  "' "$dwm_config"
grep -Fq "match = \"class_g = 'dmenu'\";" "$picom_config"

printf '%s\n' "dmenu style source tests passed"
