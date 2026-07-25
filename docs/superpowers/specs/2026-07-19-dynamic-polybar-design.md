# Dynamic Polybar Design

## Goal

将现有 Debian + dwm 顶栏调整为已确认效果图的风格：左侧只显示有窗口的 dwm 标签，并用“应用图标 + 应用名称”表达；中间显示日期时间；右侧提供托盘、输入法、亮度、音量、网络、电池和电源操作。

## Constraints

- 保留现有 dwm + Anybar + Polybar 架构。
- 不增加桌面环境、Eww 或常驻窗口扫描进程。
- 空标签完全隐藏且不占宽度。
- 每个显示器只显示并控制自己的九个 dwm 标签。
- 一个标签有多个窗口时，显示该标签最近聚焦窗口对应的应用。
- 不显示 Apps 启动器、歌曲信息或播放控制。
- dmenu 继续只通过现有快捷键启动。
- 系统托盘只运行在主显示器，因为 X11 同一会话只能有一个托盘所有者。
- 所有配置继续由 `debian-desktop` 仓库管理。
- 保留现有未提交改动，不做无关重构。

## Visual Structure

```text
[◉] [▣ Terminal] [◉ Chrome] [◆ IntelliJ IDEA]    [Sun Jul 19  14:30]    [tray] [EN] [☀ 100%] [VOL 95%] [Wi-Fi] [BAT 95%] [⏻]
```

- 顶栏高度保持约 28px。
- 背景采用半透明深蓝；左侧活动标签使用克制的红色胶囊高亮。
- 文字使用 JetBrains Mono，图标使用当前字体可稳定显示的单色 Unicode 符号，避免为品牌图标单独引入字体包。
- 非活动标签透明显示；紧急标签使用红色警示背景。
- 中间时间严格居中。
- 右侧保持紧凑、等距和可点击。

## Architecture

### dwm owns workspace metadata

扩展现有 `setdesktopnames()`，由 dwm 使用内部的 monitor、tag、client 和 focus stack 生成动态 `_NET_DESKTOP_NAMES`。这比后台脚本轮询 X11 更简单，也不会重复维护窗口到标签的映射。

`config.h` 中维护 `AppLabel` 映射表。匹配 `WM_CLASS` 后生成稳定标签，例如：

- `St` → `▣ Terminal`
- `Google-chrome` → `◉ Chrome`
- `jetbrains-idea` → `◆ IntelliJ IDEA`
- 未知应用 → `▪ <WM_CLASS>`

每个 monitor 按九个 tag 输出名称。空 tag 输出空字符串；非空 tag 从 monitor focus stack 中选择第一个匹配 client，因此代表最近聚焦窗口。

动态名称在窗口聚焦、创建、销毁、重新打标签和移动显示器后更新。

### Polybar owns presentation and actions

保留 `internal/xworkspaces`：

- `pin-workspaces = true` 保证双屏独立。
- active 标签使用红色背景。
- 空名称不渲染。
- 点击行为继续通过 EWMH 切换标签。

新增模块：

- `system-mark`：左侧系统符号。
- `tray`：仅主显示器加载 `internal/tray`。
- `input-method`：显示 `EN` 或 `中`，点击切换 fcitx5。
- `brightness`：按当前 Polybar 实例的 `MONITOR` 使用 `xrandr --brightness`，滚轮按 5% 调节，范围 40%–100%。
- `pulseaudio`：显示音量，点击打开 pavucontrol，右键静音，滚轮调节。
- `wlan`、`battery`：保留并压缩文案。
- `power`：点击后使用 dmenu 选择 Suspend、Logout、Reboot 或 Shutdown。

`launch.sh` 识别 `polybar --list-monitors` 中的 primary 标记，通过环境变量只给主显示器加入 tray，其余模块每个显示器都有。

## Files

- `suckless/dwm/dwm.c`：生成并刷新动态桌面名称。
- `suckless/dwm/config.h`：应用标签映射。
- `polybar/config.ini`：视觉样式和模块组合。
- `polybar/launch.sh`：主屏托盘和每屏模块注入。
- `polybar/brightness.sh`：每屏亮度读取与调节。
- `polybar/input-method.sh`：fcitx5 状态与切换。
- `polybar/power-menu.sh`：dmenu 电源菜单。
- `scripts/prepare-suckless.sh`：记录状态栏所需的既有依赖，不增加可选图标字体。
- `tests/dwm_dynamic_desktop_names_source_test.sh`：动态标签源码约束。
- `tests/polybar_reference_style_source_test.sh`：状态栏模块和多屏约束。
- `tests/polybar_helpers_test.sh`：辅助脚本行为和语法测试。

## Error Handling

- 无法读取 `WM_CLASS` 时使用 `▪ App`。
- fcitx5 不可访问时显示 `--`，点击命令静默失败，不阻塞 Polybar。
- 无法读取显示器亮度时显示 `☀ --`；所有调整值都限制在 40%–100%。
- 电源菜单取消选择时不执行操作。
- 非主显示器不创建 tray，避免随机抢占托盘所有权。
- 任一辅助脚本失败不得终止 Polybar 或 dwm。

## Verification

- 新测试先在现有代码上失败，再实现最小改动使其通过。
- `sh -n` 检查所有新增脚本。
- 运行现有 Polybar 多屏测试和新增测试。
- `make` 编译 dwm。
- 原子替换 `/home/dev/.local/bin/dwm`。
- 重启 dwm 后，用 `xprop -root _NET_DESKTOP_NAMES` 验证空标签为空、非空标签为应用名。
- 验证两个 Polybar 各自显示本屏标签，只有主屏出现托盘。
- 验证输入法、亮度、音量和电源菜单交互。

## Rollback

所有改动集中在上述文件。回退对应提交并重新编译 dwm、重启 Polybar 即可恢复当前状态，不修改用户项目、开发环境或系统服务。

