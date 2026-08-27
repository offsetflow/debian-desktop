#!/usr/bin/env python3
"""Render the visual layer used by the i3lock launcher."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

import cairo


MONITOR_RE = re.compile(r"^(\d+)x(\d+)([+-]\d+)([+-]\d+)$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--background", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--logo", type=Path)
    parser.add_argument("--monitors", default="1920x1080+0+0")
    return parser.parse_args()


def parse_monitors(value: str) -> tuple[list[tuple[int, int, int, int]], int, int]:
    monitors: list[tuple[int, int, int, int]] = []
    for spec in value.split():
        match = MONITOR_RE.match(spec)
        if not match:
            continue
        width, height, x, y = (int(part) for part in match.groups())
        if width > 0 and height > 0:
            monitors.append((width, height, x, y))

    if not monitors:
        monitors = [(1920, 1080, 0, 0)]

    min_x = min(monitor[2] for monitor in monitors)
    min_y = min(monitor[3] for monitor in monitors)
    normalized = [
        (width, height, x - min_x, y - min_y)
        for width, height, x, y in monitors
    ]
    canvas_width = max(x + width for width, height, x, y in normalized)
    canvas_height = max(y + height for width, height, x, y in normalized)
    return normalized, canvas_width, canvas_height


def color(hex_value: str, alpha: float = 1.0) -> tuple[float, float, float, float]:
    value = hex_value.removeprefix("#")
    return (
        int(value[0:2], 16) / 255,
        int(value[2:4], 16) / 255,
        int(value[4:6], 16) / 255,
        alpha,
    )


def paint_cover(
    context: cairo.Context,
    image: cairo.ImageSurface,
    x: float,
    y: float,
    width: float,
    height: float,
) -> None:
    image_width = image.get_width()
    image_height = image.get_height()
    scale = max(width / image_width, height / image_height)
    draw_width = image_width * scale
    draw_height = image_height * scale

    context.save()
    context.rectangle(x, y, width, height)
    context.clip()
    context.translate(x + (width - draw_width) / 2, y + (height - draw_height) / 2)
    context.scale(scale, scale)
    context.set_source_surface(image, 0, 0)
    context.paint()
    context.restore()


def draw_monitor(
    context: cairo.Context,
    background: cairo.ImageSurface,
    logo: cairo.ImageSurface | None,
    monitor: tuple[int, int, int, int],
) -> None:
    width, height, x, y = monitor
    center_x = x + width / 2

    paint_cover(context, background, x, y, width, height)

    context.rectangle(x, y, width, height)
    context.set_source_rgba(*color("#100A24", 0.25))
    context.fill()

    vignette = cairo.RadialGradient(
        center_x,
        y + height * 0.43,
        height * 0.08,
        center_x,
        y + height * 0.48,
        max(width, height) * 0.68,
    )
    vignette.add_color_stop_rgba(0, 0.12, 0.07, 0.22, 0)
    vignette.add_color_stop_rgba(1, 0.02, 0.01, 0.08, 0.48)
    context.rectangle(x, y, width, height)
    context.set_source(vignette)
    context.fill()

    if logo is not None:
        # Match i3lock-color's indicator center and leave enough space for the
        # keypress arc around the Debian swirl.
        logo_size = min(width, height) * 0.09
        logo_scale = min(
            logo_size / logo.get_width(),
            logo_size / logo.get_height(),
        )
        context.save()
        context.translate(
            center_x - logo.get_width() * logo_scale / 2,
            y + height * 0.50 - logo.get_height() * logo_scale / 2,
        )
        context.scale(logo_scale, logo_scale)
        context.set_source_surface(logo, 0, 0)
        context.get_source().set_filter(cairo.FILTER_BEST)
        context.paint_with_alpha(0.95)
        context.restore()


def main() -> None:
    args = parse_args()
    monitors, canvas_width, canvas_height = parse_monitors(args.monitors)

    background = cairo.ImageSurface.create_from_png(str(args.background))
    logo = (
        cairo.ImageSurface.create_from_png(str(args.logo))
        if args.logo is not None and args.logo.is_file()
        else None
    )
    output = cairo.ImageSurface(cairo.FORMAT_ARGB32, canvas_width, canvas_height)
    context = cairo.Context(output)
    for monitor in monitors:
        draw_monitor(context, background, logo, monitor)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    output.write_to_png(str(args.output))


if __name__ == "__main__":
    main()
