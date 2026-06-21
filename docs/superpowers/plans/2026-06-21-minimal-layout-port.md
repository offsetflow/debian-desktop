# Minimal Layout Port Implementation Plan

**Goal:** 从 `yaocccc/dwm` 最小移植 Overview、Magic Grid 和“新窗口追加到右侧栈区”行为，同时保留现有 Anybar、EWMH 和 Polybar 集成。

**Scope:** 仅修改 `suckless/dwm/config.def.h`、`suckless/dwm/config.h`、`suckless/dwm/config.mk` 和 `suckless/dwm/dwm.c`。不引入原仓库的托盘、圆角、透明、窗口隐藏、全局窗口、Rofi 或脚本。

## Task 1: 新窗口追加到右侧栈区

- 修改 `attach(Client *c)`：遍历 `c->mon->clients` 到链表尾部，再追加新窗口。
- 保留 `pop()` 调用 `attach()` 的现状，因此手动 `zoom` 后被提升的窗口仍会进入主区。
- 编译验证：`make -C suckless/dwm clean && make -C suckless/dwm`。
- 提交：`feat: keep new windows in the stack area`。

## Task 2: 最小 Gaps 基础

- 增加水平/垂直内间距与外间距配置。
- Tile 与后续 Magic Grid 共用 gap 变量。
- 单窗口时启用 smart gaps，取消外边距。
- 提供 gap 开关与统一增减函数，不移植 vanitygaps 的额外布局。
- 编译验证并提交：`feat: add minimal window gaps`。

## Task 3: Magic Grid 布局

- 从参考实现移植 `magicgrid()` 和 `grid()`。
- 一窗口时居中显示；两窗口时并排居中；更多窗口时按接近正方形的网格排列。
- 在 `layouts[]` 增加 `{ "###", magicgrid }`。
- 快捷键使用 `Alt+Shift+Space` 选择 Magic Grid，`Alt+T` 返回 Tile。
- 编译验证，并通过打开 1、2、3、5 个 `st` 窗口人工检查布局。
- 提交：`feat: add magic grid layout`。

## Task 4: Overview

- 在 `Client` 中增加预览窗口、缩放图像和坐标状态。
- 移植窗口截图、缩放、预览布局、鼠标悬停、点击选择和 `Alt+Tab` 轮换逻辑。
- `Alt+A` 打开当前显示器全部标签的窗口预览；再次按 `Alt+A` 退出并聚焦当前预览；点击窗口也可选择。
- 在 `config.mk` 增加 XRender 链接：`-lXrender`。
- 在关闭客户端与退出 dwm 时释放 `XImage`、预览窗口、Pixmap 和 Picture，避免资源泄漏。
- 编译验证，并人工检查：
  - 当前显示器多个标签的窗口都会出现；
  - 另一显示器窗口不出现；
  - `Alt+Tab` 可轮换；
  - 鼠标点击可选择；
  - 关闭预览后窗口恢复；
  - Polybar 继续常驻且多屏正常。
- 提交：`feat: add window overview`。

## Task 5: 最终验证

- 重新编译无错误、无新增编译警告。
- 验证 Tile、Magic Grid、Overview、Polybar 和双显示器。
- 不自动安装到 `/usr/local/bin`；编译通过后由用户执行：

```bash
sudo make -C ~/workspace/personal/debian-desktop/suckless/dwm install
```

- 保持 `baseline-suckless` 和 `main` 不变，所有改动留在 `codex/polybar-anybar` 分支。
