/* See LICENSE file for copyright and license details. */
/* Default settings; can be overriden by command line. */

static int topbar = 1;                      /* -b option; if 0, dmenu appears at bottom */
static int centered = 1;                    /* -c option; center dmenu on the target monitor */
static int fuzzy = 1;                       /* -F option; if 0, disable fuzzy matching */
static const unsigned int alpha = 0xa0;     /* frosted background opacity */
static const unsigned int menu_width = 680; /* centered menu width */
/* -fn option overrides fonts[0]; default X11 font or font set */
static const char *fonts[] = {
	"JetBrains Mono:size=11",
	"Noto Sans CJK SC:size=11",
	"FontAwesome:size=11"
};
static const char *prompt      = NULL;      /* -p  option; prompt to the left of input field */
static const char *colors[SchemeLast][2] = {
	/*                   fg         bg       */
	[SchemeNorm]          = { "#dce7eb", "#1d3040" },
	[SchemeSel]           = { "#edf7f8", "#0e6070" },
	[SchemeNormHighlight] = { "#6bc4d2", "#1d3040" },
	[SchemeSelHighlight]  = { "#ffffff", "#0e6070" },
	[SchemeInput]         = { "#edf4f6", "#405661" },
	[SchemeOut]           = { "#edf4f6", "#324955" },
	[SchemeBorder]        = { "#536b75", "#1d3040" },
};
static const unsigned int alphas[SchemeLast][2] = {
	[SchemeNorm]          = { OPAQUE, alpha },
	[SchemeSel]           = { OPAQUE, 0xbc },
	[SchemeNormHighlight] = { OPAQUE, alpha },
	[SchemeSelHighlight]  = { OPAQUE, 0xbc },
	[SchemeInput]         = { OPAQUE, 0xb0 },
	[SchemeOut]           = { OPAQUE, alpha },
	[SchemeBorder]        = { OPAQUE, OPAQUE },
};
/* -l option; if nonzero, dmenu uses vertical list with given number of lines */
static unsigned int lines      = 8;
/* -h option; minimum height of a menu line */
static unsigned int lineheight = 34;
static unsigned int min_lineheight = 8;
/* Window border; a nonzero width lets Picom apply rounded corners. */
static unsigned int border_width = 1;

/*
 * Characters not considered part of a word while deleting words
 * for example: " /?\"&[]"
 */
static const char worddelimiters[] = " ";
