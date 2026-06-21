# dwm 快捷键速查

当前 `MODKEY` 是 `Alt`。

## 启动与退出

| 快捷键 | 功能 |
|---|---|
| `Alt + Shift + Enter` | 打开 `st` 终端 |
| `Alt + P` | 打开 `dmenu` 程序启动器 |
| `Alt + Shift + C` | 关闭当前窗口 |
| `Alt + Shift + Q` | 退出 dwm |
| `Alt + B` | 显示或隐藏 Polybar |

## 窗口操作

| 快捷键 | 功能 |
|---|---|
| `Alt + J` | 聚焦下一个窗口 |
| `Alt + K` | 聚焦上一个窗口 |
| `Alt + Enter` | 将当前窗口提升为左侧主窗口 |
| `Alt + Shift + F` | 切换当前窗口的平铺/浮动状态 |
| `Alt + H` | 缩小左侧主区域 |
| `Alt + L` | 放大左侧主区域 |
| `Alt + I` | 增加主区域窗口数量 |
| `Alt + D` | 减少主区域窗口数量 |

新打开的窗口默认追加到右侧栈区，不会替换左侧主窗口。

## 布局

| 快捷键 | 功能 |
|---|---|
| `Alt + T` | Tile：左侧主窗口，右侧纵向栈 |
| `Alt + F` | Floating：自由浮动布局 |
| `Alt + M` | Monocle：当前窗口铺满可用区域 |
| `Alt + Shift + Space` | Magic Grid：自适应网格布局 |
| `Alt + Space` | 在最近使用的两个布局之间切换 |

## 窗口间距

| 快捷键 | 功能 |
|---|---|
| `Alt + G` | 开关窗口间距 |
| `Alt + Ctrl + =` | 所有间距增加 2px |
| `Alt + Ctrl + -` | 所有间距减少 2px |

默认内外间距都是 `10px`。只有一个平铺窗口时，Smart Gaps 会取消外边距。

## Overview 窗口总览

| 快捷键 | 功能 |
|---|---|
| `Alt + A` | 打开当前显示器所有标签的窗口总览 |
| `Alt + Tab` | 在预览窗口之间轮换 |
| `Alt + A` | 选择当前预览并退出 |
| `鼠标悬停` | 选择预览窗口 |
| `鼠标左键` | 打开选中的预览窗口 |
| `Esc` | 取消并退出 Overview |

Overview 只显示当前显示器上的窗口，不混入另一块显示器。

## 标签（工作区）

下面的 `N` 代表数字 `1` 到 `9`。

| 快捷键 | 功能 |
|---|---|
| `Alt + N` | 切换到标签 N |
| `Alt + Ctrl + N` | 将标签 N 加入或移出当前视图 |
| `Alt + Shift + N` | 将当前窗口移动到标签 N |
| `Alt + Ctrl + Shift + N` | 为当前窗口追加或移除标签 N |
| `Alt + 0` | 同时显示所有标签 |
| `Alt + Shift + 0` | 让当前窗口出现在所有标签 |
| `Alt + Tab` | 返回上一个标签视图 |

Polybar 上也可以点击工作区进行切换。

## 多显示器

| 快捷键 | 功能 |
|---|---|
| `Alt + ,` | 聚焦左侧/上一台显示器 |
| `Alt + .` | 聚焦右侧/下一台显示器 |
| `Alt + Shift + ,` | 将当前窗口移动到左侧/上一台显示器 |
| `Alt + Shift + .` | 将当前窗口移动到右侧/下一台显示器 |

## 鼠标操作

| 操作 | 功能 |
|---|---|
| `Alt + 左键拖动窗口` | 移动窗口 |
| `Alt + 右键拖动窗口` | 调整窗口大小 |
| `Alt + 中键点击窗口` | 切换平铺/浮动状态 |

Polybar 已替代 dwm 原生栏，因此原生栏专用的鼠标操作通常不会使用。

## 重新编译安装

修改 `suckless/dwm/config.h` 或 `dwm.c` 后：

```bash
cd ~/workspace/personal/debian-desktop
make -C suckless/dwm clean
make -C suckless/dwm
sudo make -C suckless/dwm install
```

退出并重新启动 dwm 后生效：

```text
Alt + Shift + Q
startx
```
