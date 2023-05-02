from os import getenv
from kitty.boss import get_boss
from kitty.fast_data_types import Screen, get_options
from kitty.utils import color_as_int
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    Formatter,
    TabBarData,
    as_rgb,
    draw_attributed_string,
    draw_title,
)
from contextlib import contextmanager


@contextmanager
def save_cursor(screen: Screen):
    fg, bg, bold, italic = (
        screen.cursor.fg,
        screen.cursor.bg,
        screen.cursor.bold,
        screen.cursor.italic,
    )
    try:
        yield screen.cursor
    finally:
        screen.cursor.fg = fg
        screen.cursor.bg = bg
        screen.cursor.bold = bold
        screen.cursor.italic = italic


def get_current_layout() -> str:
    layout_name = "?"
    tm = get_boss().active_tab_manager
    if tm is not None:
        tab = tm.active_tab
        if tab is not None and tab.current_layout is not None:
            layout_name = tab.current_layout.name
    return layout_name


def get_cwd() -> str:
    cwd = "?"
    tab_manager = get_boss().active_tab_manager
    if tab_manager is not None:
        window = tab_manager.active_window
        if window is not None:
            cwd = window.cwd_of_child

    # TODO: handle truncation
    return cwd.replace(getenv("HOME") or "", "~")


def n_windows() -> int:
    nwindows = 0
    tab_manager = get_boss().active_tab_manager
    if tab_manager is not None:
        active_tab = tab_manager.active_tab
        if active_tab is not None:
            nwindows = len(active_tab.windows)
    return nwindows


# I miss u dwm :^(
LAYOUT_TABLE = {
    "tall": "[]=",
    "stack": "[m]",
}


def rgb(color):
    return as_rgb(color_as_int(color))


def draw_left_prompt(screen: Screen, index: int) -> int:
    opts = get_options()
    if index != 1:
        return screen.cursor.x
    layout = get_current_layout()
    with save_cursor(screen) as cursor:
        cursor.bold = True
        cursor.fg = rgb(opts.active_tab_foreground)
        cursor.bg = rgb(opts.active_tab_background)

        def draw_sep():
            screen.draw(" | ")

        screen.draw(LAYOUT_TABLE.get(layout, "[?]"))
        draw_sep()
        screen.draw(f"w:{n_windows()}")

    screen.cursor.x += 1

    return screen.cursor.x


def draw_right_prompt(screen: Screen, is_last: bool) -> int:
    if not is_last:
        return screen.cursor.x

    cell = " " + get_cwd()

    thing = screen.columns - screen.cursor.x - len(cell)
    if thing < len(cell):
        return screen.cursor.x

    # screen.draw(" " * thing)
    screen.cursor.x = screen.columns - len(cell)
    screen.draw(cell)

    return screen.cursor.x


def draw_tabs(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
) -> int:
    orig_fg = screen.cursor.fg
    left_sep, right_sep = ("", "") if draw_data.tab_bar_edge == "top" else ("", "")
    tab_bg = screen.cursor.bg
    slant_fg = as_rgb(color_as_int(draw_data.default_bg))

    def draw_sep(which: str) -> None:
        screen.cursor.bg = tab_bg
        screen.cursor.fg = slant_fg
        screen.draw(which)
        screen.cursor.bg = tab_bg
        screen.cursor.fg = orig_fg

    max_tab_length += 1
    if max_tab_length <= 1:
        screen.draw("…")
    elif max_tab_length == 2:
        screen.draw("…|")
    elif max_tab_length < 6:
        draw_sep(left_sep)
        screen.draw(
            (" " if max_tab_length == 5 else "")
            + "…"
            + (" " if max_tab_length >= 4 else "")
        )
        draw_sep(right_sep)
    else:
        draw_sep(left_sep)
        screen.draw(" ")
        draw_title(draw_data, screen, tab, index, max_tab_length)
        extra = screen.cursor.x - before - max_tab_length
        if extra >= 0:
            screen.cursor.x -= extra + 3
            screen.draw("…")
        elif extra == -1:
            screen.cursor.x -= 2
            screen.draw("…")
        screen.draw(" ")
        draw_sep(right_sep)

    return screen.cursor.x


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    draw_left_prompt(screen, index)
    draw_tabs(draw_data, screen, tab, before, max_tab_length, index)
    draw_right_prompt(screen, is_last)
    return screen.cursor.x
