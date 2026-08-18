#!/usr/bin/python3
"""A small translucent calendar popup for the Polybar date module."""

import calendar
import os
import signal
import sys
import warnings
from datetime import date, datetime
from pathlib import Path

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("Pango", "1.0")
gi.require_version("PangoCairo", "1.0")
from gi.repository import Gdk, GLib, Gtk, Pango, PangoCairo  # noqa: E402


WINDOW_WIDTH = 382
WINDOW_HEIGHT = 480
GRID_LEFT = 20
GRID_TOP = 218
GRID_WIDTH = 342
CELL_WIDTH = GRID_WIDTH / 7
ROW_HEIGHT = 38

WHITE = (0.96, 0.96, 1.00, 1.00)
TEXT = (0.86, 0.87, 0.93, 1.00)
MUTED = (0.53, 0.55, 0.66, 1.00)
FAINT = (0.35, 0.36, 0.44, 1.00)
PURPLE = (0.56, 0.39, 1.00, 1.00)
PINK = (1.00, 0.43, 0.68, 1.00)


def rounded_rectangle(cr, x, y, width, height, radius):
    radius = min(radius, width / 2, height / 2)
    cr.new_sub_path()
    cr.arc(x + width - radius, y + radius, radius, -1.5708, 0)
    cr.arc(x + width - radius, y + height - radius, radius, 0, 1.5708)
    cr.arc(x + radius, y + height - radius, radius, 1.5708, 3.1416)
    cr.arc(x + radius, y + radius, radius, 3.1416, 4.7124)
    cr.close_path()


def set_source(cr, color):
    cr.set_source_rgba(*color)


def draw_text(cr, text, x, y, size, color, weight=Pango.Weight.NORMAL, align="left"):
    layout = PangoCairo.create_layout(cr)
    description = Pango.FontDescription()
    description.set_family("Noto Sans CJK SC")
    description.set_absolute_size(size * Pango.SCALE)
    description.set_weight(weight)
    layout.set_font_description(description)
    layout.set_text(str(text), -1)
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


class CalendarPopup(Gtk.Window):
    WEEKDAYS = ("一", "二", "三", "四", "五", "六", "日")
    WEEKDAY_NAMES = (
        "星期一",
        "星期二",
        "星期三",
        "星期四",
        "星期五",
        "星期六",
        "星期日",
    )

    def __init__(self, pid_file):
        super().__init__(title="Calendar")
        self.pid_file = Path(pid_file) if pid_file else None
        self.today = date.today()
        self.selected = self.today
        self.view_year = self.today.year
        self.view_month = self.today.month
        self.cell_dates = []

        with warnings.catch_warnings():
            warnings.simplefilter("ignore", DeprecationWarning)
            self.set_wmclass("desktop-calendar", "DesktopCalendar")
        self.set_name("desktop-calendar")
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
            | Gdk.EventMask.SCROLL_MASK
            | Gdk.EventMask.SMOOTH_SCROLL_MASK
        )
        self.add(self.area)

        self.area.connect("draw", self.on_draw)
        self.area.connect("button-press-event", self.on_button_press)
        self.area.connect("scroll-event", self.on_scroll)
        self.connect("key-press-event", self.on_key_press)
        self.connect("destroy", Gtk.main_quit)

        GLib.timeout_add_seconds(30, self.refresh_clock)

    def refresh_clock(self):
        new_today = date.today()
        if new_today != self.today:
            old_today = self.today
            self.today = new_today
            if self.selected == old_today:
                self.selected = new_today
        self.area.queue_draw()
        return GLib.SOURCE_CONTINUE

    def month_cells(self):
        weeks = calendar.Calendar(firstweekday=0).monthdatescalendar(
            self.view_year, self.view_month
        )
        while len(weeks) < 6:
            final_day = weeks[-1][-1]
            weeks.append([final_day.fromordinal(final_day.toordinal() + day) for day in range(1, 8)])
        return [day for week in weeks[:6] for day in week]

    def on_draw(self, _widget, cr):
        now = datetime.now()
        display_date = self.selected
        date_status = "今天" if display_date == self.today else "已选择"

        cr.set_operator(1)
        cr.set_source_rgba(0, 0, 0, 0)
        cr.paint()
        cr.set_operator(2)

        rounded_rectangle(cr, 0.5, 0.5, WINDOW_WIDTH - 1, WINDOW_HEIGHT - 1, 18)
        cr.set_source_rgba(0.045, 0.048, 0.078, 0.78)
        cr.fill_preserve()
        cr.set_line_width(1.2)
        cr.set_source_rgba(1, 1, 1, 0.22)
        cr.stroke()

        # A translucent inner sheet and accent blooms give the blurred surface depth.
        rounded_rectangle(cr, 12, 12, WINDOW_WIDTH - 24, 106, 14)
        cr.set_source_rgba(1, 1, 1, 0.025)
        cr.fill()
        cr.arc(WINDOW_WIDTH - 22, 12, 92, 0, 6.2832)
        cr.set_source_rgba(0.52, 0.31, 1.0, 0.12)
        cr.fill()
        cr.arc(10, WINDOW_HEIGHT - 8, 78, 0, 6.2832)
        cr.set_source_rgba(1.0, 0.28, 0.62, 0.075)
        cr.fill()

        draw_text(cr, "万 年 历", 24, 21, 10, MUTED, Pango.Weight.BOLD)
        cr.arc(WINDOW_WIDTH - 93, 29, 3, 0, 6.2832)
        set_source(cr, (0.45, 0.95, 0.75, 1.0))
        cr.fill()
        draw_text(
            cr,
            now.strftime("%H:%M"),
            WINDOW_WIDTH - 24,
            18,
            13,
            WHITE,
            Pango.Weight.SEMIBOLD,
            "right",
        )

        draw_text(cr, f"{display_date.day:02d}", 23, 51, 48, WHITE, Pango.Weight.BOLD)
        draw_text(
            cr,
            self.WEEKDAY_NAMES[display_date.weekday()],
            102,
            61,
            17,
            TEXT,
            Pango.Weight.SEMIBOLD,
        )
        draw_text(
            cr,
            f"{display_date.year}年{display_date.month}月 · {date_status}",
            102,
            90,
            11,
            MUTED,
        )

        cr.move_to(20, 129.5)
        cr.line_to(WINDOW_WIDTH - 20, 129.5)
        cr.set_line_width(1)
        cr.set_source_rgba(1, 1, 1, 0.075)
        cr.stroke()

        self.draw_nav_button(cr, 28, 159, "‹")
        self.draw_nav_button(cr, WINDOW_WIDTH - 28, 159, "›")
        draw_text(
            cr,
            f"{self.view_year}年  {self.view_month:02d}月",
            WINDOW_WIDTH / 2,
            147,
            15,
            WHITE,
            Pango.Weight.SEMIBOLD,
            "center",
        )

        for column, weekday in enumerate(self.WEEKDAYS):
            color = PINK if column >= 5 else MUTED
            draw_text(
                cr,
                weekday,
                GRID_LEFT + CELL_WIDTH * (column + 0.5),
                190,
                10,
                color,
                Pango.Weight.SEMIBOLD,
                "center",
            )

        self.cell_dates = self.month_cells()
        for index, cell_date in enumerate(self.cell_dates):
            row, column = divmod(index, 7)
            center_x = GRID_LEFT + CELL_WIDTH * (column + 0.5)
            center_y = GRID_TOP + ROW_HEIGHT * row + ROW_HEIGHT / 2
            in_month = cell_date.month == self.view_month
            is_today = cell_date == self.today
            is_selected = cell_date == self.selected

            if is_today:
                cr.new_path()
                cr.arc(center_x, center_y, 19, 0, 6.2832)
                cr.set_source_rgba(0.56, 0.39, 1.0, 0.16)
                cr.fill()
                cr.new_path()
                cr.arc(center_x, center_y, 15.5, 0, 6.2832)
                set_source(cr, PURPLE)
                cr.fill()
            elif is_selected:
                cr.new_path()
                cr.arc(center_x, center_y, 15.5, 0, 6.2832)
                cr.set_source_rgba(1, 1, 1, 0.08)
                cr.fill_preserve()
                cr.set_source_rgba(*PURPLE[:3], 0.75)
                cr.set_line_width(1.2)
                cr.stroke()

            if is_today:
                color = WHITE
                weight = Pango.Weight.BOLD
            elif not in_month:
                color = FAINT
                weight = Pango.Weight.NORMAL
            elif column >= 5:
                color = (1.0, 0.60, 0.76, 1.0)
                weight = Pango.Weight.NORMAL
            else:
                color = TEXT
                weight = Pango.Weight.NORMAL

            draw_text(
                cr,
                cell_date.day,
                center_x,
                center_y - 8,
                11,
                color,
                weight,
                "center",
            )

        cr.move_to(20, 451.5)
        cr.line_to(WINDOW_WIDTH - 20, 451.5)
        cr.set_line_width(1)
        cr.set_source_rgba(1, 1, 1, 0.06)
        cr.stroke()
        draw_text(cr, "滚轮切换月份", 22, 460, 9, FAINT)
        draw_text(cr, "ESC 关闭", WINDOW_WIDTH - 22, 460, 9, MUTED, align="right")
        return False

    @staticmethod
    def draw_nav_button(cr, center_x, center_y, glyph):
        cr.arc(center_x, center_y, 15, 0, 6.2832)
        cr.set_source_rgba(1, 1, 1, 0.065)
        cr.fill()
        draw_text(cr, glyph, center_x, center_y - 11, 17, TEXT, align="center")

    def change_month(self, delta):
        month_index = self.view_year * 12 + self.view_month - 1 + delta
        self.view_year, month_zero = divmod(month_index, 12)
        self.view_month = month_zero + 1
        self.area.queue_draw()

    def reset_to_today(self):
        self.today = date.today()
        self.selected = self.today
        self.view_year = self.today.year
        self.view_month = self.today.month
        self.area.queue_draw()

    def on_button_press(self, _widget, event):
        if event.button != 1:
            return False

        if event.y < 130:
            self.reset_to_today()
            return True
        if 140 <= event.y <= 180 and event.x <= 54:
            self.change_month(-1)
            return True
        if 140 <= event.y <= 180 and event.x >= WINDOW_WIDTH - 54:
            self.change_month(1)
            return True
        if 140 <= event.y <= 180:
            self.reset_to_today()
            return True

        row = int((event.y - GRID_TOP) // ROW_HEIGHT)
        column = int((event.x - GRID_LEFT) // CELL_WIDTH)
        if 0 <= row < 6 and 0 <= column < 7 and self.cell_dates:
            selected = self.cell_dates[row * 7 + column]
            self.selected = selected
            if selected.month != self.view_month or selected.year != self.view_year:
                self.view_year = selected.year
                self.view_month = selected.month
            self.area.queue_draw()
            return True
        return False

    def on_scroll(self, _widget, event):
        if event.direction == Gdk.ScrollDirection.UP:
            self.change_month(-1)
        elif event.direction == Gdk.ScrollDirection.DOWN:
            self.change_month(1)
        else:
            _delta_x, delta_y = event.get_scroll_deltas()[1:]
            if delta_y:
                self.change_month(1 if delta_y > 0 else -1)
        return True

    def on_key_press(self, _widget, event):
        key = Gdk.keyval_name(event.keyval)
        if key in ("Escape", "q"):
            self.destroy()
            return True
        if key in ("Left", "Page_Up"):
            self.change_month(-1)
            return True
        if key in ("Right", "Page_Down"):
            self.change_month(1)
            return True
        if key == "Home":
            self.reset_to_today()
            return True
        return False

    def position_below_pointer(self):
        display = Gdk.Display.get_default()
        seat = display.get_default_seat()
        pointer = seat.get_pointer()
        _screen, pointer_x, pointer_y = pointer.get_position()
        monitor = display.get_monitor_at_point(pointer_x, pointer_y)
        geometry = monitor.get_geometry()

        x = int(pointer_x - WINDOW_WIDTH / 2)
        x = max(geometry.x + 8, min(x, geometry.x + geometry.width - WINDOW_WIDTH - 8))

        if pointer_y <= geometry.y + 80:
            y = geometry.y + 42
        else:
            y = pointer_y + 12
        if y + WINDOW_HEIGHT > geometry.y + geometry.height - 8:
            y = max(geometry.y + 8, pointer_y - WINDOW_HEIGHT - 12)

        self.move(x, int(y))
        self.area.grab_focus()
        return GLib.SOURCE_REMOVE


def main():
    pid_file = sys.argv[1] if len(sys.argv) > 1 else None
    window = CalendarPopup(pid_file)
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
    GLib.idle_add(window.position_below_pointer)
    Gtk.main()


if __name__ == "__main__":
    main()
