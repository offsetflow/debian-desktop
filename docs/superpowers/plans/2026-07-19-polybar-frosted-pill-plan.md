# Polybar Frosted Pill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将现有 Polybar 改为真正透明磨砂背景，并让当前 dwm 应用标签显示为红色圆角胶囊。

**Architecture:** Polybar 负责 ARGB 背景和活动标签三段式胶囊；Picom 负责对 Polybar 背后的桌面进行 `dual_kawase` 模糊。Symbols Nerd Font Mono 只提供胶囊左右端字形，安装过程由独立脚本负责并从 `prepare-suckless.sh` 调用。

**Tech Stack:** Polybar 3.7、Picom v13、Fontconfig、Symbols Nerd Font Mono 3.4.0、POSIX shell。

## Global Constraints

- 不修改 dwm 的 `tile`、`magicgrid`、gaps、窗口几何或快捷键行为。
- 空标签保持隐藏，普通已占用标签保持透明。
- 两个显示器分别显示自己的标签，托盘只出现在主屏。
- 所有新增脚本使用 UTF-8，并通过 `sh -n`。

---

### Task 1: 锁定磨砂与胶囊配置约束

**Files:**
- Create: `tests/polybar_frosted_pill_source_test.sh`
- Test: `polybar/config.ini`
- Test: `picom/picom.conf`
- Test: `scripts/prepare-suckless.sh`

**Interfaces:**
- Consumes: 现有 Polybar 与 Picom 配置。
- Produces: 一个可检测真透明、Polybar 模糊规则、圆角字形和字体安装入口的源码回归测试。

- [ ] **Step 1: 写失败测试**

测试必须断言：`pseudo-transparency = false`；活动标签包含 ``、``；Polybar 指定 `Symbols Nerd Font Mono`；Picom 的 Polybar 规则开启模糊；通用 dock 规则排除 Polybar；prepare 脚本调用字体安装脚本。

- [ ] **Step 2: 运行测试确认失败**

Run: `sh tests/polybar_frosted_pill_source_test.sh`

Expected: `FAIL: Polybar must use real ARGB transparency`

### Task 2: 安装最小符号字体

**Files:**
- Create: `scripts/install-symbols-nerd-font.sh`
- Modify: `scripts/prepare-suckless.sh`
- Test: `tests/polybar_frosted_pill_source_test.sh`

**Interfaces:**
- Consumes: `curl`、`tar`、`fc-cache`。
- Produces: `$HOME/.local/share/fonts/NerdFontsSymbolsOnly/SymbolsNerdFontMono-Regular.ttf` 和字体族 `Symbols Nerd Font Mono`。

- [ ] **Step 1: 实现幂等字体安装脚本**

固定下载 Nerd Fonts v3.4.0 的 `NerdFontsSymbolsOnly.tar.xz`，仅保留 Mono Regular 字体；字体已存在时跳过下载。

- [ ] **Step 2: 接入 prepare 脚本**

APT 最小依赖增加 `curl`、`xz-utils`，依赖安装完成后调用字体安装脚本。

- [ ] **Step 3: 验证字体**

Run: `fc-match 'Symbols Nerd Font Mono'`

Expected: 输出 `SymbolsNerdFontMono-Regular.ttf`。

### Task 3: 启用真透明磨砂和活动标签胶囊

**Files:**
- Modify: `polybar/config.ini`
- Modify: `picom/picom.conf`
- Test: `tests/polybar_frosted_pill_source_test.sh`

**Interfaces:**
- Consumes: ``、`` 字形和 Picom `rules`。
- Produces: ARGB 磨砂顶栏与红色半透明活动标签胶囊。

- [ ] **Step 1: 修改 Polybar**

关闭伪透明；注册 Symbols Nerd Font Mono；活动标签使用透明左端、红色主体和透明右端组成胶囊；移除矩形活动背景配置。

- [ ] **Step 2: 修改 Picom**

保留 Polybar 专用 `blur-background = true`；让通用 dock 规则只匹配非 Polybar dock，避免后续规则覆盖。

- [ ] **Step 3: 运行源码测试**

Run: `sh tests/polybar_frosted_pill_source_test.sh && sh tests/polybar_reference_style_source_test.sh`

Expected: 两项均输出 `OK`。

### Task 4: 实时加载与视觉验证

**Files:**
- Verify: `polybar/launch.sh`
- Verify: `picom/launch.sh`

**Interfaces:**
- Consumes: 已安装字体和新配置。
- Produces: 当前 X11 会话中的最终视觉效果与截图。

- [ ] **Step 1: 语法与回归验证**

Run: `sh -n scripts/install-symbols-nerd-font.sh polybar/launch.sh picom/launch.sh`，然后执行现有 Polybar 定向测试。

- [ ] **Step 2: 重新加载 Picom 和 Polybar**

运行两个 `launch.sh`，确认各自进程数量正确且日志无 error/warn。

- [ ] **Step 3: 截图验证**

使用 `ffmpeg -f x11grab` 抓取主屏，确认壁纸透过状态栏并被柔化、活动标签为圆角红色胶囊、窗口布局未改变。
