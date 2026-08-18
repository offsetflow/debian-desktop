#!/usr/bin/python3
"""macOS-inspired notification history popup backed by Dunst."""

import html
import json
import os
import re
import signal
import subprocess
import sys
import time
import warnings
from dataclasses import dataclass
from pathlib import Path

import cairo
import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("Pango", "1.0")
gi.require_version("PangoCairo", "1.0")
from gi.repository import Gdk, GLib, Gtk, Pango, PangoCairo  # noqa: E402


WINDOW_WIDTH = 430
WINDOW_HEIGHT = 700
CARD_LEFT = 18
CARD_TOP = 112
CARD_WIDTH = WINDOW_WIDTH - 36
CARD_HEIGHT = 126
CARD_GAP = 13
VISIBLE_CARDS = 4

WHITE = (0.97, 0.97, 0.99, 1.0)
TEXT = (0.88, 0.89, 0.93, 1.0)
MUTED = (0.60, 0.62, 0.69, 1.0)
FAINT = (0.43, 0.45, 0.52, 1.0)
VIOLET = (0.56, 0.39, 1.0, 1.0)
CYAN = (0.32, 0.73, 1.0, 1.0)
MINT = (0.37, 0.86, 0.67, 1.0)
PINK = (1.0, 0.43, 0.66, 1.0)

TAG_PATTERN = re.compile(r"<[^>]*>")
SPACE_PATTERN = re.compile(r"\s+")


@dataclass
class Notification:
    notification_id: int
    appname: str
    summary: str
    body: str
    category: str
    urgency: str
    timestamp: int


def rounded_rectangle(cr, x, y, width, height, radius):
    radius = min(radius, width / 2, height / 2)
    cr.new_path()
    cr.arc(x + width - radius, y + radius, radius, -1.5708, 0)
    cr.arc(x + width - radius, y + height - radius, radius, 0, 1.5708)
    cr.arc(x + radius, y + height - radius, radius, 1.5708, 3.1416)
    cr.arc(x + radius, y + radius, radius, 3.1416, 4.7124)
    cr.close_path()


def set_source(cr, color):
    cr.set_source_rgba(*color)


def draw_text(
    cr,
    text,
    x,
    y,
    size,
    color,
    weight=Pango.Weight.NORMAL,
    align="left",
    max_width=None,
    family="Noto Sans CJK SC",
):
    layout = PangoCairo.create_layout(cr)
    description = Pango.FontDescription()
    description.set_family(family)
    description.set_absolute_size(size * Pango.SCALE)
    description.set_weight(weight)
    layout.set_font_description(description)
    layout.set_single_paragraph_mode(True)
    layout.set_text(str(text), -1)
    if max_width is not None:
        layout.set_width(int(max_width * Pango.SCALE))
        layout.set_ellipsize(Pango.EllipsizeMode.END)
    _, logical = layout.get_pixel_extents()

    if align == "center":
        x -= logical.width / 2 + logical.x
    elif align == "right":
        x -= logical.width + logical.x
    else:
        x -= logical.x

    cr.move_to(x, y - logical.y)
    set_source(cr, color)
    PangoCairo.show_layout(cr, layout)


def clean_text(value):
    text = html.unescape(str(value or ""))
    text = TAG_PATTERN.sub("", text)
    return SPACE_PATTERN.sub(" ", text).strip()


def unwrap_variant(value, default=""):
    if isinstance(value, dict) and "data" in value:
        return value.get("data", default)
    return value if value is not None else default


def parse_dunst_history(payload):
    history = json.loads(payload)
    notifications = []
    raw_data = history.get("data", [])

    # busctl serializes Dunst's aa{sv} return value as one outer result array
    # containing the actual notification dictionaries.
    if len(raw_data) == 1 and isinstance(raw_data[0], list):
        raw_items = raw_data[0]
    else:
        raw_items = raw_data

    for raw_item in raw_items:
        fields = {}
        if isinstance(raw_item, list):
            for field_group in raw_item:
                if isinstance(field_group, dict):
                    fields.update(field_group)
        elif isinstance(raw_item, dict):
            fields.update(raw_item)

        values = {key: unwrap_variant(value) for key, value in fields.items()}
        try:
            notification_id = int(values.get("id", 0))
            timestamp = int(values.get("timestamp", 0))
        except (TypeError, ValueError):
            continue

        appname = clean_text(values.get("appname")) or "系统通知"
        summary = clean_text(values.get("summary")) or appname
        body = clean_text(values.get("body"))
        notifications.append(
            Notification(
                notification_id=notification_id,
                appname=appname,
                summary=summary,
                body=body,
                category=clean_text(values.get("category")),
                urgency=clean_text(values.get("urgency")) or "NORMAL",
                timestamp=timestamp,
            )
        )

    notifications.sort(key=lambda item: item.timestamp, reverse=True)
    return notifications


def demo_notifications():
    now = int(time.monotonic() * 1_000_000)
    return [
        Notification(3, "系统", "系统更新", "有 5 个软件包可以更新", "system", "NORMAL", now),
        Notification(
            2,
            "Flameshot",
            "截图",
            "图片已保存到 Pictures",
            "image",
            "NORMAL",
            now - 5 * 60 * 1_000_000,
        ),
        Notification(
            1,
            "电源管理",
            "电池",
            "已充至 80%，已停止充电",
            "device",
            "LOW",
            now - 12 * 60 * 1_000_000,
        ),
    ]


def relative_time(timestamp):
    if timestamp <= 0:
        return ""
    age = max(0, time.monotonic() - timestamp / 1_000_000)
    if age < 60:
        return "刚刚"
    if age < 3600:
        return f"{int(age // 60)} 分钟前"
    if age < 86400:
        return f"{int(age // 3600)} 小时前"
    return f"{int(age // 86400)} 天前"


def icon_style(notification):
    identity = " ".join(
        (
            notification.appname,
            notification.summary,
            notification.category,
        )
    ).lower()
    if any(word in identity for word in ("battery", "power", "电池", "电源")):
        return MINT, "\uf240"
    if any(word in identity for word in ("image", "picture", "screenshot", "截图", "flameshot")):
        return CYAN, "\uf03e"
    if any(word in identity for word in ("update", "package", "apt", "更新", "软件包")):
        return VIOLET, "\uf1b2"
    if any(word in identity for word in ("mail", "email", "邮件")):
        return PINK, "\uf0e0"
    return VIOLET, "\uf0f3"


class NotificationCenter(Gtk.Window):
    def __init__(self, pid_file=None, demo=False):
        super().__init__(title="Notification Center")
        self.pid_file = Path(pid_file) if pid_file else None
        self.demo = demo
        self.dunstctl = os.environ.get("DUNSTCTL_BIN", "/usr/bin/dunstctl")
        self.notifications = demo_notifications() if demo else []
        self.load_error = ""
        self.offset = 0
        self.hovered_card = None
        self.clear_hovered = False
        self.card_regions = []
        self.clear_region = (WINDOW_WIDTH - 122, 17, 104, 67)

        with warnings.catch_warnings():
            warnings.simplefilter("ignore", DeprecationWarning)
            self.set_wmclass("desktop-notification-center", "DesktopNotificationCenter")
        self.set_name("desktop-notification-center")
        self.set_default_size(WINDOW_WIDTH, WINDOW_HEIGHT)
        self.set_resizable(False)
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)
        self.set_type_hint(Gdk.WindowTypeHint.UTILITY)
        self.set_app_paintable(True)

        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual is not None and screen.is_composited():
            self.set_visual(visual)

        self.area = Gtk.DrawingArea()
        self.area.set_size_request(WINDOW_WIDTH, WINDOW_HEIGHT)
        self.area.set_can_focus(True)
        self.area.add_events(
            Gdk.EventMask.BUTTON_PRESS_MASK
            | Gdk.EventMask.POINTER_MOTION_MASK
            | Gdk.EventMask.LEAVE_NOTIFY_MASK
            | Gdk.EventMask.SCROLL_MASK
            | Gdk.EventMask.SMOOTH_SCROLL_MASK
        )
        self.add(self.area)

        self.area.connect("draw", self.on_draw)
        self.area.connect("button-press-event", self.on_button_press)
        self.area.connect("motion-notify-event", self.on_motion)
        self.area.connect("leave-notify-event", self.on_leave)
        self.area.connect("scroll-event", self.on_scroll)
        self.connect("key-press-event", self.on_key_press)
        self.connect("destroy", Gtk.main_quit)

        if not self.demo:
            self.reload_history()
            GLib.timeout_add_seconds(2, self.refresh_history)

    def run_dunstctl(self, *arguments):
        try:
            result = subprocess.run(
                [self.dunstctl, *arguments],
                check=False,
                capture_output=True,
                text=True,
                timeout=2,
            )
        except (OSError, subprocess.TimeoutExpired):
            return None
        return result

    def reload_history(self):
        result = self.run_dunstctl("history")
        if result is None or result.returncode != 0:
            self.notifications = []
            self.load_error = "通知服务未启动"
        else:
            try:
                self.notifications = parse_dunst_history(result.stdout)
                self.load_error = ""
            except (json.JSONDecodeError, TypeError, ValueError):
                self.notifications = []
                self.load_error = "无法读取通知历史"

        self.offset = min(self.offset, max(0, len(self.notifications) - VISIBLE_CARDS))
        self.area.queue_draw()

    def refresh_history(self):
        self.reload_history()
        return GLib.SOURCE_CONTINUE

    def on_draw(self, _widget, cr):
        cr.set_operator(cairo.OPERATOR_SOURCE)
        cr.set_source_rgba(0, 0, 0, 0)
        cr.paint()
        cr.set_operator(cairo.OPERATOR_OVER)

        rounded_rectangle(cr, 0.6, 0.6, WINDOW_WIDTH - 1.2, WINDOW_HEIGHT - 1.2, 20)
        cr.set_source_rgba(0.052, 0.061, 0.085, 0.84)
        cr.fill_preserve()
        cr.set_line_width(1.2)
        cr.set_source_rgba(1, 1, 1, 0.21)
        cr.stroke()

        rounded_rectangle(cr, 11, 11, WINDOW_WIDTH - 22, 82, 15)
        cr.set_source_rgba(1, 1, 1, 0.025)
        cr.fill()

        draw_text(cr, "通知中心", 23, 21, 21, WHITE, Pango.Weight.BOLD)
        count_text = f"{len(self.notifications)} 条通知"
        draw_text(cr, count_text, 24, 60, 10, MUTED, Pango.Weight.NORMAL)
        draw_text(
            cr,
            "全部清除",
            WINDOW_WIDTH - 24,
            32,
            10,
            WHITE if self.clear_hovered else MUTED,
            Pango.Weight.NORMAL,
            "right",
        )

        cr.new_path()
        cr.move_to(18, 98.5)
        cr.line_to(WINDOW_WIDTH - 18, 98.5)
        cr.set_line_width(1)
        cr.set_source_rgba(1, 1, 1, 0.07)
        cr.stroke()

        self.card_regions = []
        visible = self.notifications[self.offset : self.offset + VISIBLE_CARDS]
        for visible_index, notification in enumerate(visible):
            absolute_index = self.offset + visible_index
            y = CARD_TOP + visible_index * (CARD_HEIGHT + CARD_GAP)
            self.draw_notification_card(cr, notification, absolute_index, y)

        if not self.notifications:
            self.draw_empty_state(cr)

        cr.new_path()
        cr.move_to(18, WINDOW_HEIGHT - 43.5)
        cr.line_to(WINDOW_WIDTH - 18, WINDOW_HEIGHT - 43.5)
        cr.set_line_width(1)
        cr.set_source_rgba(1, 1, 1, 0.06)
        cr.stroke()

        if self.notifications:
            draw_text(cr, "滚轮查看更多 · 右键移除", 22, WINDOW_HEIGHT - 31, 9, FAINT)
            page_end = min(len(self.notifications), self.offset + len(visible))
            draw_text(
                cr,
                f"{self.offset + 1}–{page_end} / {len(self.notifications)}",
                WINDOW_WIDTH - 22,
                WINDOW_HEIGHT - 31,
                9,
                MUTED,
                align="right",
            )
        else:
            draw_text(
                cr,
                "更早的通知会显示在这里",
                WINDOW_WIDTH / 2,
                WINDOW_HEIGHT - 31,
                9,
                FAINT,
                align="center",
            )
        return False

    def draw_notification_card(self, cr, notification, index, y):
        hovered = self.hovered_card == index
        rounded_rectangle(cr, CARD_LEFT, y, CARD_WIDTH, CARD_HEIGHT, 18)
        cr.set_source_rgba(1, 1, 1, 0.095 if hovered else 0.065)
        cr.fill_preserve()
        cr.set_line_width(1)
        cr.set_source_rgba(1, 1, 1, 0.18 if hovered else 0.12)
        cr.stroke()

        accent, glyph = icon_style(notification)
        icon_x = CARD_LEFT + 18
        icon_y = y + 34
        rounded_rectangle(cr, icon_x, icon_y, 56, 56, 14)
        cr.set_source_rgba(*accent[:3], 0.86)
        cr.fill()
        rounded_rectangle(cr, icon_x + 1, icon_y + 1, 54, 26, 13)
        cr.set_source_rgba(1, 1, 1, 0.10)
        cr.fill()
        draw_text(
            cr,
            glyph,
            icon_x + 28,
            icon_y + 17,
            20,
            WHITE,
            Pango.Weight.NORMAL,
            "center",
            family="FontAwesome",
        )

        text_x = CARD_LEFT + 91
        text_width = CARD_WIDTH - 115
        app_label = notification.appname
        if app_label.casefold() == notification.summary.casefold():
            app_label = "系统通知"
        draw_text(cr, app_label, text_x, y + 15, 8.5, MUTED, max_width=text_width - 80)
        draw_text(
            cr,
            relative_time(notification.timestamp),
            CARD_LEFT + CARD_WIDTH - 17,
            y + 15,
            8.5,
            FAINT,
            align="right",
        )
        draw_text(
            cr,
            notification.summary,
            text_x,
            y + 40,
            13,
            WHITE,
            Pango.Weight.SEMIBOLD,
            max_width=text_width,
        )
        body = notification.body or "无更多内容"
        draw_text(cr, body, text_x, y + 70, 10, TEXT, max_width=text_width)

        self.card_regions.append((CARD_LEFT, y, CARD_WIDTH, CARD_HEIGHT, index))

    def draw_empty_state(self, cr):
        center_y = 307
        cr.new_path()
        cr.arc(WINDOW_WIDTH / 2, center_y, 39, 0, 6.2832)
        cr.set_source_rgba(1, 1, 1, 0.055)
        cr.fill()
        draw_text(
            cr,
            "\uf0f3",
            WINDOW_WIDTH / 2,
            center_y - 18,
            22,
            MUTED,
            align="center",
            family="FontAwesome",
        )
        message = self.load_error or "暂无通知"
        draw_text(cr, message, WINDOW_WIDTH / 2, center_y + 58, 14, TEXT, Pango.Weight.SEMIBOLD, "center")
        draw_text(
            cr,
            "新的通知会自动保存在这里",
            WINDOW_WIDTH / 2,
            center_y + 90,
            10,
            FAINT,
            align="center",
        )

    @staticmethod
    def point_in_region(x, y, region):
        region_x, region_y, width, height = region[:4]
        return region_x <= x <= region_x + width and region_y <= y <= region_y + height

    def on_motion(self, _widget, event):
        clear_hovered = self.point_in_region(event.x, event.y, self.clear_region)
        hovered_card = None
        for region in self.card_regions:
            if self.point_in_region(event.x, event.y, region):
                hovered_card = region[4]
                break
        if clear_hovered != self.clear_hovered or hovered_card != self.hovered_card:
            self.clear_hovered = clear_hovered
            self.hovered_card = hovered_card
            self.area.queue_draw()
        return True

    def on_leave(self, _widget, _event):
        self.clear_hovered = False
        self.hovered_card = None
        self.area.queue_draw()
        return True

    def on_button_press(self, _widget, event):
        if event.button == 1 and self.point_in_region(event.x, event.y, self.clear_region):
            if self.demo:
                self.notifications = []
                self.area.queue_draw()
            else:
                self.run_dunstctl("history-clear")
                self.reload_history()
            return True

        selected_index = None
        for region in self.card_regions:
            if self.point_in_region(event.x, event.y, region):
                selected_index = region[4]
                break
        if selected_index is None or selected_index >= len(self.notifications):
            return False

        notification = self.notifications[selected_index]
        if event.button == 1:
            if not self.demo:
                self.run_dunstctl("history-pop", str(notification.notification_id))
            self.destroy()
            return True
        if event.button == 3:
            if self.demo:
                del self.notifications[selected_index]
                self.offset = min(self.offset, max(0, len(self.notifications) - VISIBLE_CARDS))
                self.area.queue_draw()
            else:
                self.run_dunstctl("history-rm", str(notification.notification_id))
                self.reload_history()
            return True
        return False

    def scroll_by(self, delta):
        maximum = max(0, len(self.notifications) - VISIBLE_CARDS)
        new_offset = max(0, min(self.offset + delta, maximum))
        if new_offset != self.offset:
            self.offset = new_offset
            self.area.queue_draw()

    def on_scroll(self, _widget, event):
        if event.direction == Gdk.ScrollDirection.UP:
            self.scroll_by(-1)
        elif event.direction == Gdk.ScrollDirection.DOWN:
            self.scroll_by(1)
        else:
            _delta_x, delta_y = event.get_scroll_deltas()[1:]
            if delta_y:
                self.scroll_by(1 if delta_y > 0 else -1)
        return True

    def on_key_press(self, _widget, event):
        key = Gdk.keyval_name(event.keyval)
        if key in ("Escape", "q"):
            self.destroy()
            return True
        if key in ("Down", "Page_Down"):
            self.scroll_by(1)
            return True
        if key in ("Up", "Page_Up"):
            self.scroll_by(-1)
            return True
        if key in ("r", "R") and not self.demo:
            self.reload_history()
            return True
        return False

    def position_at_monitor_edge(self):
        display = Gdk.Display.get_default()
        seat = display.get_default_seat()
        pointer = seat.get_pointer()
        _screen, pointer_x, pointer_y = pointer.get_position()
        monitor = display.get_monitor_at_point(pointer_x, pointer_y)
        geometry = monitor.get_geometry()

        x = geometry.x + geometry.width - WINDOW_WIDTH - 14
        y = geometry.y + 44
        if y + WINDOW_HEIGHT > geometry.y + geometry.height - 8:
            y = geometry.y + max(8, geometry.height - WINDOW_HEIGHT - 8)
        self.move(int(x), int(y))
        self.area.grab_focus()
        return GLib.SOURCE_REMOVE


def main():
    arguments = [argument for argument in sys.argv[1:] if argument != "--demo"]
    pid_file = arguments[0] if arguments else None
    demo = "--demo" in sys.argv[1:]
    window = NotificationCenter(pid_file=pid_file, demo=demo)
    current_pid = str(os.getpid())

    if window.pid_file:
        window.pid_file.write_text(current_pid + "\n", encoding="ascii")

    def close_popup(_signum=None, _frame=None):
        GLib.idle_add(window.destroy)

    def cleanup_pid_file(*_args):
        if not window.pid_file:
            return
        try:
            if window.pid_file.read_text(encoding="ascii").strip() == current_pid:
                window.pid_file.unlink()
        except FileNotFoundError:
            pass

    signal.signal(signal.SIGTERM, close_popup)
    signal.signal(signal.SIGINT, close_popup)
    window.connect("destroy", cleanup_pid_file)
    window.show_all()
    GLib.idle_add(window.position_at_monitor_edge)
    Gtk.main()


if __name__ == "__main__":
    main()
